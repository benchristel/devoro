class Store
  def initialize(redis)
    @redis = redis
  end

  def enqueue_uri(uri, referrer_rating)
    return if queued? uri

    domain = URI(uri).host
    increase_rating uri, referrer_rating
    if not @redis.sismember('domains', domain)
      puts "        Found domain: #{domain}"
      @redis.sadd('domains', domain)
      increase_rating uri, referrer_rating
    end
  end

  def add_page(web_document)
    @redis.sadd('crawled', web_document.url)
  end

  def crawled?(uri)
    @redis.sismember('crawled', uri)
  end

  def pop_uri
    first = @redis.zrevrange('ranked_urls', 0, 0)[0]
    @redis.zrem 'ranked_urls', first
    first
  end

  def top(n)
    all_uris[0...n]
  end

  def all_uris
    @redis.zrevrange 'ranked_urls', 0, -1
  end

  def count_uris
    @redis.zcard 'ranked_urls'
  end

  private

  def queued?(uri)
    @redis.zscore 'ranked_urls', uri
  end

  def increase_rating(uri, amount)
    @redis.zincrby 'ranked_urls', amount, uri.to_s
  end
end
