require "url_parser/version"
require "domainatrix"
require "postrank-uri"
require "addressable/uri"
require "digest/sha1"

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

  # https://secure.wikimedia.org/wikipedia/en/wiki/URI_scheme
  SCHEMES = [
    'file', 'ftp', 'gopher', 'h323', 'hdl', 'http', 'https',
    'imap', 'magnet', 'mailto', 'mms', 'news', 'nntp', 'prospero',
    'rsync', 'rtsp', 'rtspu', 'sftp', 'shttp', 'sip', 'sips',
    'snews', 'svn', 'svn+ssh', 'telnet', 'wais',
    # Unofficial schemes
    'aim', 'callto', 'cvs', 'facetime', 'feed', 'git', 'gtalk',
    'irc', 'ircs', 'irc6', 'itms', 'mms', 'msnim', 'mvn', 'skype',
    'ssh', 'smb', 'svn', 'ymsg', 'webcal'
  ]

  DEFAULT_SCHEMES = [
    'http', 'https', 'ftp', 'mailto', 'file', 'ssh', 'feed',
    'cvs', 'git', 'mvn', 'nntp', 'shttp', 'svn', 'webcal'
  ]

  module Error; end

  class InvalidScheme
    include UrlParser::Error
  end

  def self.call(text, options = {})
    urls = []
    PostRank::URI.extract(text).each do |url|
      urls << new(url, options)
    end
    urls
  end

  def self.new(url, options = {})
    Base.new(url, options)
  end

  class Base

    attr_reader :url, :original_url, :raise_errors

    attr_accessor :errors

    def initialize(url, options = {})
      @schemes        = options.fetch(:schemes) { UrlParser::DEFAULT_SCHEMES }
      @clean          = options.fetch(:clean) { false }
      @raise_errors   = options.fetch(:raise_errors) { false }
      @errors         = []
      @original_url   = url
      @url            = @clean ? clean(url) : parse(url)
      prepare
    end

    def schemes
      Array.wrap(@schemes)
    end

    def clean!
      @parser = nil
      @url = clean(url)
      @clean = true
      self
    end

    def parser
      tag_errors do
        @parser ||= Domainatrix.parse(to_s)
      end
    end

    def to_s
      return '' if errors.any?
      url.to_s
    end

    def hash(options = {})
      return nil if errors.any?
      clean = options.fetch(:clean) { nil }
      if clean.nil?
        Digest::SHA1.hexdigest(url.to_s)
      else
        Digest::SHA1.hexdigest(
          clean ? clean(original_url) : parse(original_url)
        )
      end
    end

    def valid?
      errors.empty?
    end

    def join(relative_path)
      return nil if errors.any?
      UrlParser.new(
        Addressable::URI.join(url, relative_path).to_s
      )
    end

    # URI Components

    def scheme
      return nil if errors.any?
      url.scheme
    end

    def username
      return nil if errors.any?
      url.user
    end
    alias_method :user, :username

    def password
      return nil if errors.any?
      url.password
    end

    def userinfo
      return nil if errors.any?
      url.userinfo
    end

    def www
      return nil if errors.any?
      return nil if parser.subdomain.empty?
      parts = slice_domain.split('.')
      parts.first =~ /www?\d*/ ? parts.shift : nil
    end

    def subdomain
      return nil if errors.any?
      return nil if parser.subdomain.empty?
      parts = slice_domain.split('.')
      parts.shift if parts.first =~ /www?\d*/
      parts.compact.join('.')
    end

    def subdomains
      return nil if errors.any?
      return nil if parser.subdomain.empty?
      [ www, subdomain ].compact.join('.')
    end

    def domain_name
      return nil if errors.any?
      parser.domain.empty? ? nil : parser.domain
    end

    def domain
      return nil if errors.any?
      if parser.domain_with_public_suffix.empty?
        nil
      else
        parser.domain_with_public_suffix
      end
    end

    def tld
      return nil if errors.any?
      tld = parser.public_suffix
      tld.empty? ? nil : tld
    end

    def hostname
      return nil if errors.any?
      url.host
    end

    def port
      return nil if errors.any?
      url.port
    end

    def host
      return nil if errors.any?
      name = [ hostname, port ].compact.join(':')
      name.empty? ? nil : name
    end

    def origin
      return nil if errors.any?
      url.origin == "null" ? nil : url.origin
    end

    def authority
      return nil if errors.any?
      url.authority
    end

    def site
      return nil if errors.any?
      url.site
    end

    def directory
      return nil if errors.any?
      parts = path.split('/')
      return '/' if parts.empty?
      parts.pop unless segment.to_s.empty?
      parts.unshift('') unless parts.first.to_s.empty?
      parts.compact.join('/')
    end

    def path
      return nil if errors.any?
      url.path
    end

    def segment
      return nil if errors.any?
      path =~ /\/\z/ ? nil : path.split('/').last
    end

    def filename
      return nil if errors.any?
      return 'index.html' if segment.to_s.empty?
      return '' if suffix.to_s.empty?
      segment
    end

    def suffix
      return nil if errors.any?
      ext = File.extname(path)
      ext[0] = '' if ext[0] == '.'
      ext.empty? ? nil : ext
    end

    def query
      return nil if errors.any?
      url.query
    end

    def query_values
      return {} if errors.any?
      url.query_values.to_h
    end

    def fragment
      return nil if errors.any?
      url.fragment
    end

    def resource
      return nil if errors.any?
      name = [
        [ segment, query ].compact.join('?'), fragment
      ].compact.join('#')
      name.empty? ? nil : name
    end

    def relative?
      return nil if errors.any?
      url.relative?
    end

    def absolute?
      return nil if errors.any?
      url.absolute?
    end

    def localhost?
      return nil if errors.any?
      !!(hostname =~ /(\A|\.)localhost\z/)
    end

    private

    def slice_domain
      parser.subdomain.tap{ |s| s.slice!(domain) }
    end

    def tag_errors
      yield
    rescue Exception => error
      unless error.singleton_class.include?(UrlParser::Error)
        error.extend(UrlParser::Error)
      end
      @errors << error
      raise if raise_errors
    end

    def parse(url)
      tag_errors do
        PostRank::URI.parse(url, raw: true)
      end
    end

    def clean(url)
      tag_errors do
        PostRank::URI.clean(url, raw: true)
      end
    end

    # Initialize parser to ensure no errors are raised
    #
    def prepare
      parser
    end

  end

end
