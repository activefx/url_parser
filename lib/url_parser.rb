require "url_parser/version"
require "domainatrix"
require "postrank-uri"
require "addressable/uri"

class Array

  def self.wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end unless respond_to?(:wrap)

end

module UrlParser

  module Error; end

  def self.call(text)
    urls = []
    PostRank::URI.extract(text).each do |url|
      urls << new(url)
    end
    urls
  end

  def self.new(url, options = {})
    Base.new(url, options)
  end

  class Base

    DEFAULT_SCHEMES = [
      'http', 'https', 'ftp', 'mailto', 'file', 'ssh', 'feed',
      'cvs', 'git', 'mvn', 'nntp', 'shttp', 'svn'
    ]

    attr_reader :url

    def initialize(url, options = {})
      tag_errors do
        @schemes = options.fetch(:schemes) { DEFAULT_SCHEMES }
        @url = PostRank::URI.clean(url)
      end
    end

    def schemes
      Array.wrap(@schemes)
    end

    def uri
      tag_errors do
        @uri ||= URI.parse(url) rescue nil
      end
    end

    def values
      uri ? uri.instance_values : {}
    end

    def valid?
      return true if domain == 'localhost'
      return false if uri.nil?
      return false unless schemes.include? uri.scheme
      return false unless uri.host =~ /\./
      true
    end

    def parser
      tag_errors do
        @parser ||= Domainatrix.parse(url)
      end
    end

    def domain
      parser.domain_with_public_suffix
    end

    def subdomain
      unless parser.subdomain.empty?
        parts = parser.subdomain.tap{ |s| s.slice!(domain) }.split('.')
        parts.shift if parts.first =~ /www?\d*/
        (parts << domain).join('.')
      else
        domain
      end
    end

    private

    def tag_errors
      yield
    rescue Exception => error
      error.extend(UrlParser::Error)
      raise
    end

  end

end
