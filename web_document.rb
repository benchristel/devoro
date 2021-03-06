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
    return 0 if top_words.count == 0
    ((Set.new(top_words) - BORING_WORDS).count * 20 / top_words.count).round
  end

  def words
    plaintext.split(/[^a-zA-Z]+/).map(&:downcase)
  end

  def top_words
    @top_words ||= WordCounter.new(words).top(20)
  end

  def error?
    response.status.to_i > 399
  rescue
    true
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
    response.body_str.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
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
  rescue Curl::Err::HostResolutionError => e
    RULES << BanApexDomain.new(URI(url).host)
    STDERR.puts "ERROR in response: #{e.class} : #{e}"
    @response = NullResponse.new
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
end

class NullResponse
  def status
    999
  end

  def body_str
    ''
  end
end
