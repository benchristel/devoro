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

      WebDocument.new(url).canonical_links
        .select { |link| interesting_link? link }
        .reject { |link| already_crawled? link }
        .each   { |link|
          enqueue link
        }
        .map  { |link| URI(link).host }
        .uniq
        .each { |domain| puts "        Found domain: #{domain}" }

      redis.sadd('crawled', url)
    end
  end

  private

  def enqueue(url)
    redis.sadd 'urls', url
  end

  def already_crawled?(url)
    redis.sismember 'crawled', url
  end

  def interesting_link?(link)
    LinkJudge.new(link).approve?
  end
end

class LinkJudge
  def initialize(uri_string)
    @uri = URI(uri_string)
  end

  def approve?
    RULES.none? { |rule| rule.reject? @uri }
  end
end

class Rule
  def reject?
    raise NotImplementedError.new 'Subclasses of Rule must implement reject?'
  end
end

class BanApexDomain < Rule
  # domain can be a string or regex
  def initialize(domain)
    @domain = domain
  end

  def reject?(uri)
    #TODO this is imprecise
    uri.host && uri.host[@domain]
  end
end

class BanPathComponent < Rule
  # bad can be a string or regex
  def initialize(bad)
    @bad = bad
  end

  def reject?(uri)
    components(uri).any? { |c| c[@bad] }
  end

  def components(uri)
    uri.path ? uri.path.split('/') : []
  end
end

class NoopRule < Rule
  def reject?(uri)
    false
  end
end

RULES = [
  BanApexDomain.new('bbc'),
  BanApexDomain.new('facebook'),
  BanApexDomain.new('goo.gl'),
  BanApexDomain.new('google'),
  BanApexDomain.new('instagram'),
  BanApexDomain.new('microsoft'),
  BanApexDomain.new('pinterest'),
  BanApexDomain.new('snapchat'),
  BanApexDomain.new('soundcloud'),
  BanApexDomain.new('twitter'),
  BanApexDomain.new('youtube'),
  BanPathComponent.new(/^user/),
  BanPathComponent.new(/user$/),
  BanPathComponent.new(/^edit/),
  BanPathComponent.new(/^profile/),
  BanPathComponent.new(/^search/),
  BanPathComponent.new(/^new/),
  BanPathComponent.new(/^login/),
  BanPathComponent.new('tos'),
  BanPathComponent.new('privacy'),
  BanPathComponent.new('copyright'),

  NoopRule.new()
]

