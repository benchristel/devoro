require_relative './web_document.rb'
require_relative './store.rb'

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

class Rule
  def reject?
    raise NotImplementedError.new 'Subclasses of Rule must implement reject?'
  end

  def name
    'unnamed'
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

  def name
    "ban domain #{@domain}"
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

  def name
    "ban path #{@bad}"
  end

  private

  def components(uri)
    uri.path ? uri.path.split('/') : []
  end
end

class BanNonHtml < Rule
  def reject?(uri)
    # reject if uri has an extension that is not .htm(l)
    /\.[a-z]{3}[a-z](\?|$)/ =~ uri.to_s &&
    /\.html?(\?|$)/ !~ uri.to_s &&
    /\.aspx?(\?|$)/ !~ uri.to_s &&
    /\.php(\?|$)/ !~ uri.to_s
  end

  def name
    "non-html"
  end
end

class NoopRule < Rule
  def reject?(uri)
    false
  end
end

MOBILE_DOMAINS = /(\.|^)m(obile)?\./
NON_ENGLISH_WIKIPEDIAS = /(?<!en)\.wikipedia\.org/

RULES = [
  BanApexDomain.new('amazon'),
  BanApexDomain.new('bbc'),
  BanApexDomain.new('facebook'),
  BanApexDomain.new('flickr'),
  BanApexDomain.new('goo.gl'),
  BanApexDomain.new('google'),
  BanApexDomain.new('instagram'),
  BanApexDomain.new('linkedin'),
  BanApexDomain.new('marketing'),
  BanApexDomain.new('microsoft'),
  BanApexDomain.new('pcmag'),
  BanApexDomain.new('pinterest'),
  BanApexDomain.new('snapchat'),
  BanApexDomain.new('soundcloud'),
  BanApexDomain.new(/^t.co$/),
  BanApexDomain.new('tumblr'),
  BanApexDomain.new('twitter'),
  BanApexDomain.new('wikiquote'),
  BanApexDomain.new('wiktionary'),
  BanApexDomain.new('wikibooks'),
  BanApexDomain.new('wikivoyage'),
  BanApexDomain.new('wikisource'),
  BanApexDomain.new('wikimedia'),
  BanApexDomain.new('wikinews'),
  BanApexDomain.new('wikiversity'),
  BanApexDomain.new(NON_ENGLISH_WIKIPEDIAS),
  BanApexDomain.new('yahoo'),
  BanApexDomain.new('youtube'),
  BanApexDomain.new(MOBILE_DOMAINS),
  BanPathComponent.new(/^user/),
  BanPathComponent.new(/user$/),
  BanPathComponent.new(/^edit/),
  BanPathComponent.new(/^profile/),
  BanPathComponent.new(/^search/),
  BanPathComponent.new(/^login/),
  BanPathComponent.new(/^tos$/),
  BanPathComponent.new('privacy'),
  BanPathComponent.new('copyright'),
  BanNonHtml.new(),

  NoopRule.new()
]
