require_relative './web_document.rb'
require_relative './store.rb'
require_relative './rules.rb'

class Crawler
  attr_accessor :store

  def initialize(redis)
    self.store = Store.new(redis)
  end

  def run
    puts "There are #{store.count_uris} urls to crawl..."
    last_domain = nil

    while url = store.top_uri
      page = WebDocument.new(url)
      rating = page.rating
      puts "#{rating}\t#{url}"

      page.canonical_links
        .select { |link| interesting_link? link }
        .reject { |link| already_crawled? link or link == url }
        .each   { |link| store.enqueue_uri link, rating }

      sleep 1 if last_domain == URI(url).host

      store.add_page page
      last_domain = URI(url).host
    end

    puts "Finished eating the entire web!"
  end

  private

  def interesting_link?(link)
    LinkJudge.new(link).approve?
  end

  def already_crawled?(link)
    store.crawled? link
  end
end

class LinkJudge
  def initialize(uri_string)
    @uri = URI(uri_string)
    @ban_log = File.open('./rejects.log', 'a')
  end

  def approve?
    RULES.each { |rule|
      if rule.reject? @uri
        @ban_log.puts "Rule '#{rule.name}' rejected #{@uri}"
        return false
      end
    }
    true
  end
end
