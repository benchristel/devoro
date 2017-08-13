class Store
  def initialize(redis)
    @redis = redis
    @results = File.open('./pages.tsv', 'a')
  end

  def enqueue_uri(uri, referrer_rating)
    return if queued? uri

    domain = URI(uri).host
    increase_rating uri, referrer_rating
    if not @redis.sismember('domains', domain)
      puts "        Found domain: #{domain}"
      @redis.sadd('domains', domain)
      # boost the priority of newly-discovered domains
      # referenced by high-quality pages
      if referrer_rating > 18
        increase_rating uri, referrer_rating
      end
    end
  end

  def add_page(web_document)
    @redis.sadd 'crawled', web_document.url
    remove_uri web_document.url
    return if web_document.error? || !web_document.english?
    @results.puts "#{web_document.rating}\t#{web_document.url}\t#{web_document.top_words.join(' ')}"
    @results.flush
  end

  def remove_uri(url)
    @redis.zrem 'ranked_urls', url
  end

  def crawled?(uri)
    @redis.sismember('crawled', uri)
  end

  def top_uri
    @redis.zrevrange('ranked_urls', 0, 0)[0]
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
