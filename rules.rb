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
    /\.[a-z]{3}[a-z]?(\?|$)/ =~ uri.to_s &&
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
  BanApexDomain.new('anuncioneon'),
  BanApexDomain.new('bbc'),
  BanApexDomain.new('facebook'),
  BanApexDomain.new('flickr'),
  BanApexDomain.new('geocities.com'),
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
  BanApexDomain.new('youtube'),
  BanApexDomain.new(MOBILE_DOMAINS),
  BanPathComponent.new(/^user/),
  BanPathComponent.new(/user$/),
  BanPathComponent.new(/^edit/),
  BanPathComponent.new(/^post-edit/), # blogger edit links
  BanPathComponent.new(/^profile/),
  BanPathComponent.new(/^search/),
  BanPathComponent.new(/^login/),
  BanPathComponent.new(/^tos$/),
  BanPathComponent.new('privacy'),
  BanPathComponent.new('copyright'),
  BanNonHtml.new(),

  NoopRule.new()
]
