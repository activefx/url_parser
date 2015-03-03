# https://secure.wikimedia.org/wikipedia/en/wiki/URI_scheme

require "url_parser/version"
require "url_parser/uri"

module UrlParser

  module Error; end

  def self.new(url, **options)
    URI.new(url, options)
  end

  module_function

  def tag_errors
    yield
  rescue Exception => error
    unless error.singleton_class.include?(UrlParser::Error)
      error.extend(UrlParser::Error)
    end
    raise error
  end

end
