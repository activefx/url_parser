# https://secure.wikimedia.org/wikipedia/en/wiki/URI_scheme

require "gem_config"
require "url_parser/version"
require "url_parser/domain"
# require "url_parser/redux"
require "url_parser/uri"
require 'pry'

module UrlParser
  include GemConfig::Base

  with_configuration do
    has :default_scheme, classes: String, default: 'http'
    has :scheme_map, classes: Hash, default: Hash.new
  end

  module Error; end

  # DB = YAML.load_file(File.join(File.dirname(__FILE__), '/url_parser/db.yml'))

  def self.new(url, options = {})
    warn "[DEPRECATION] `.new` is deprecated. Please use `.parse` instead."
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
