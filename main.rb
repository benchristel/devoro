require 'redis'
require 'nokogiri'
require 'curb'

redis = Redis.new

class WebDocument
  attr_accessor :url

  def initialize(url)
    self.url = url
  end

  def canonical_links
    @links ||=
    tree.search('a[href]')
      .map { |link| canonicalize(link['href']) }
  end

  private

  def tree
    @tree ||=
    Nokogiri::HTML(response_body)
  end

  def response_body
    @response_body ||=
    Curl::Easy.perform(url) do |curl|
      curl.follow_location = true
    end.body_str
  end

  def canonicalize(relative_url)
    URI.join(url, relative_url).to_s
  end
end

class Crawler
  attr_accessor :redis

  def initialize(redis)
    self.redis = redis
  end

  def run
    count = redis.scard('urls')
    puts "There are #{count} urls to crawl..."

    while url = redis.spop('urls')
      sleep 1
      puts url

      WebDocument.new(url).canonical_links.each { |link|
        puts "    Found link: #{link}"
        redis.sadd('urls', link)
      }
    end
  end
end

crawler = Crawler.new(redis)
crawler.run
