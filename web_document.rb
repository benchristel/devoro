require 'nokogiri'
require 'curl'
require './word_counter'
require './words'
require 'set'

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
    (70000 * personal_word_count.to_f /
    plaintext_length * length_score)
    .round
  end

  def words
    plaintext.split(/[^a-zA-Z]+/).map(&:downcase)
  end

  def top_words
    WordCounter.new(words).top(10)
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
    @response_body ||=
    Curl::Easy.perform(url) do |curl|
      curl.connect_timeout   = 10
      curl.dns_cache_timeout = 10
      curl.timeout           = 10
      curl.follow_location   = true
    end.body_str
  rescue => e
    STDERR.puts "ERROR in response_body: #{e.class} : #{e}"
    "<html></html>"
  end

  def canonicalize(relative_url)
    canonical = URI.join(url, relative_url)
    canonical.fragment = nil # remove the "hashtag" at the end of the URI
    canonical.to_s
  rescue
    ''
  end

  def personal_word_count
    @personal_word_count ||=
      plaintext.scan(/\b(I|[Mm]y|me|mine)\b/).count + 1
  end

  def plaintext_length
    plaintext.length + 1
  end

  def length_score
    len = plaintext.length
    return 0 if len < 140
    return 1 if len < 700
    return 2 if len < 5000
    return 3
  end
end
