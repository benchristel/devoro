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
      curl.follow_location = true
    end.body_str
  end

  def canonicalize(relative_url)
    URI.join(url, relative_url).to_s
  rescue
    ''
  end
end
