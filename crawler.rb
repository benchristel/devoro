require_relative './web_document.rb'

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
        enqueue link unless already_crawled? link
      }

      redis.sadd('crawled', url)
    end
  end

  def enqueue(url)
    redis.sadd 'urls', url
  end

  def already_crawled?(url)
    redis.sismember 'crawled', url
  end
end
