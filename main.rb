require 'redis'
require 'nokogiri'
require 'curb'

redis = Redis.new

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
      document = Nokogiri::HTML(request(url))
      links = document.search('a[href]').map { |url| url['href'] }
      
      puts url
      links.each { |link|
        puts "    Found link: #{canonicalize(link, url)}"
        redis.sadd('urls', canonicalize(link, url))
      }
    end
  end

  private

  def request(url)
    Curl::Easy.perform(url) do |curl|
      curl.follow_location = true
    end.body_str
  end

  def canonicalize(url, base)
    URI.join(base, url).to_s
  end
end

crawler = Crawler.new(redis)
crawler.run

