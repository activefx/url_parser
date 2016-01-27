# https://secure.wikimedia.org/wikipedia/en/wiki/URI_scheme

require "url_parser/version"
require "url_parser/uri"

module UrlParser

  module Error; end

  def self.new(url, options = {})
    warn "[DEPRECATION] `.new` is deprecated.  Please use `.parse` instead."
    parse(url, options)
  end

  module_function

  def parse(url, options = {})
    URI.new(url, options)
  end

  def tag_errors
    yield
  rescue StandardError => error
    unless error.singleton_class.include?(UrlParser::Error)
      error.extend(UrlParser::Error)
    end
    raise error
  end

end
