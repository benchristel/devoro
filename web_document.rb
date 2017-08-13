require 'nokogiri'
require 'curl'
require './word_counter'
require './stopwords'
require './boring_words'
require 'set'
require 'whatlanguage'

class WebDocument
  attr_accessor :url

  def initialize(url)
    self.url = url
  end

  def canonical_links
    @links ||=
    tree.search('a[href]')
      .map { |link| canonicalize(link['href']) }
      .reject(&:empty?)
  end

  def rating
    (Set.new(top_words) - BORING_WORDS).count * length_score
  end

  def words
    plaintext.split(/[^a-zA-Z]+/).map(&:downcase)
  end

  def top_words
    @top_words ||= WordCounter.new(words).top(20)
  end

  def error?
    response.status.to_i > 399
  end

  def english?
    language == :english
  end

  def language
    @language ||= WhatLanguage.new(:all).language(plaintext)
  end

  private

  def plaintext
    @plaintext ||= tree.xpath("//*[not(self::script or self::style)]/text()")
      .to_s
      .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      .squeeze(" \n\t")
  rescue ArgumentError => e
    STDERR.puts "ERROR in plaintext: #{e.class} : #{e}"
    ''
  end

  def tree
    @tree ||=
    Nokogiri::HTML(response_body)
  end

  def response_body
    response.body_str
  rescue => e
    STDERR.puts "ERROR in response_body: #{e.class} : #{e}"
    ""
  end

  def response
    @response ||= Curl::Easy.perform(url) do |curl|
      curl.connect_timeout   = 10
      curl.dns_cache_timeout = 10
      curl.timeout           = 10
      curl.follow_location   = true
    end
  rescue => e
    STDERR.puts "ERROR in response: #{e.class} : #{e}"
    @response = NullResponse.new
  end

  def canonicalize(relative_url)
    canonical = URI.join(url, relative_url)
    canonical.fragment = nil # remove the "hashtag" at the end of the URI
    canonical.to_s
  rescue
    ''
  end

  def length_score
    1
    # len = plaintext.length
    # return 2 if len < 140
    # return 3 if len < 700
    # return 4 if len < 5000
    # return 5
  end
end

class NullResponse
  def status
    999
  end

  def body_str
    ''
  end
end
