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

    while url = store.pop_uri
      puts url

      page = WebDocument.new(url)
      page.canonical_links
        .select { |link| interesting_link? link }
        .reject { |link| already_crawled? link }
        .each   { |link| store.enqueue_uri link, 1 }

      store.add_page page

      sleep 1 if last_domain == URI(url).host
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
  end

  def approve?
    RULES.each { |rule|
      if rule.reject? @uri
        STDERR.puts "Rule '#{rule.name}' rejected #{@uri}"
        return false
      end
    }
    true
  end
end
