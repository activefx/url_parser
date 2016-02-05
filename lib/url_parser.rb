require "yaml"
require "gem_config"
require "addressable/uri"
require "url_parser/version"
require "url_parser/option_setter"
require "url_parser/domain"
require "url_parser/model"
require "url_parser/parser"
require "url_parser/uri"

module UrlParser
  include GemConfig::Base

  with_configuration do
    has :default_scheme, classes: [ String, NilClass ], default: 'http'
    has :scheme_map, classes: Hash, default: Hash.new
    has :embedded_params, classes: Array, default: %w(u url)
  end

  module Error; end

  class LibraryError < StandardError
    include Error
  end

  RequiresAddressableURI  = Class.new(LibraryError)
  RequiresUrlParserDomain = Class.new(LibraryError)

  DB = YAML.load_file(File.join(File.dirname(__FILE__), '/url_parser/db.yml'))

  def self.new(url, options = {})
    warn "[DEPRECATION] `.new` is deprecated. Please use `.parse` instead."
    parse(url, options)
  end

  module_function

  # Encode a string
  #
  # Adapted from ERB::Util.url_encode
  #
  def escape(uri, options = {})
    uri.to_s.dup
      .force_encoding(Encoding::ASCII_8BIT)
      .gsub(/[^a-zA-Z0-9_\-.]/n) do
        sprintf("%%%02X", Regexp.last_match[0].unpack("C")[0])
      end
  end

  # Decode a string
  #
  # Adapted from CGI::unescape
  #
  # See also http://tools.ietf.org/html/rfc3986#section-2.3
  #
  def unescape(uri, options = {})
    encoding = options.fetch(:encoding) { Encoding::UTF_8 }

    query_spaces = proc do
      if Regexp.last_match[6]
        Regexp.last_match[0].sub(
          Regexp.last_match[6],
          Regexp.last_match[6].tr('+', ' ')
        )
      else
        Regexp.last_match[0]
      end
    end

    decode_chars = proc do
      [Regexp.last_match[1].delete('%')].pack('H*')
    end

    string = uri.to_s

    str = string.dup
      .gsub(Addressable::URI::URIREGEX, &query_spaces)
      .force_encoding(Encoding::ASCII_8BIT)
      .gsub(/((?:%[0-9a-fA-F]{2})+)/, &decode_chars)
      .force_encoding(encoding)

    str.valid_encoding? ? str : str.force_encoding(string.encoding)
  end

  def parse(url, options = {})
    URI.new(url, options)
  end

  # Wraps its argument in an array unless it is already an array
  #
  # See: activesupport/lib/active_support/core_ext/array/wrap.rb, line 36
  #
  def wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
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
