class WebDocument
  attr_accessor :url

  def initialize(url)
    self.url = url
  end

  def canonical_links
    @links ||=
    tree.search('a[href]')
      .map { |link| canonicalize(link['href']) }
      .reject(&:empty?)
  end

  private

  def tree
    @tree ||=
    Nokogiri::HTML(response_body)
  end

  def response_body
    @response_body ||=
    Curl::Easy.perform(url) do |curl|
      curl.connect_timeout   = 10
      curl.dns_cache_timeout = 10
      curl.timeout           = 10
      curl.follow_location   = true
    end.body_str
  rescue
    "<html></html>"
  end

  def canonicalize(relative_url)
    canonical = URI.join(url, relative_url)
    canonical.fragment = nil # remove the "hashtag" at the end of the URI
    canonical.to_s
  rescue
    ''
  end
end
