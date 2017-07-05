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
        redis.sadd('urls', link)
      }
    end
  end
end
