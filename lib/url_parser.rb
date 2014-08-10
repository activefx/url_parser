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


  module Error; end

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

    attr_reader :url, :original_url, :raise_errors

    def initialize(url, options = {})
      @schemes = options.fetch(:schemes) { DEFAULT_SCHEMES }
      @clean = options.fetch(:clean) { false }
      @original_url = url
      @url = @clean ? clean(url) : parse(url)
    end

    def schemes
      Array.wrap(@schemes)
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

    def parser
      tag_errors do
        @parser ||= Domainatrix.parse(to_s)
      end
    end

    def clean!
      @parser = nil
      @url = clean(url)
      @clean = true
      self
    end

    def to_s
      url.to_s
    end

    def hash(options = {})
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
      return true if localhost?
      return false unless schemes.include?(scheme)
      return false unless hostname =~ /\./
      true
    end

    def join(relative_path)
      UrlParser.new(
        Addressable::URI.join(url, relative_path).to_s
      )
    end

    # URI Components

    def scheme
      url.scheme
    end

    def username
      url.user
    end
    alias_method :user, :username

    def password
      url.password
    end

    def userinfo
      url.userinfo
    end

    def www
      return nil if parser.subdomain.empty?
      parts = slice_domain.split('.')
      parts.first =~ /www?\d*/ ? parts.shift : nil
    end

    def subdomain
      return nil if parser.subdomain.empty?
      parts = slice_domain.split('.')
      parts.shift if parts.first =~ /www?\d*/
      parts.compact.join('.')
    end

    def subdomains
      return nil if parser.subdomain.empty?
      [ www, subdomain ].compact.join('.')
    end

    def domain_name
      parser.domain.empty? ? nil : parser.domain
    end

    def domain
      if parser.domain_with_public_suffix.empty?
        nil
      else
        parser.domain_with_public_suffix
      end
    end

    def tld
      tld = parser.public_suffix
      tld.empty? ? nil : tld
    end

    def hostname
      url.host
    end

    def port
      url.port
    end

    def host
      name = [ hostname, port ].compact.join(':')
      name.empty? ? nil : name
    end

    def origin
      url.origin == "null" ? nil : url.origin
    end

    def authority
      url.authority
    end

    def site
      url.site
    end

    def directory
      parts = path.split('/')
      return '/' if parts.empty?
      parts.pop unless segment.to_s.empty?
      parts.unshift('') unless parts.first.to_s.empty?
      parts.compact.join('/')
    end

    def path
      url.path
    end

    def segment
      path =~ /\/\z/ ? nil : path.split('/').last
    end

    def filename
      return 'index.html' if segment.to_s.empty?
      return '' if suffix.to_s.empty?
      segment
    end

    def suffix
      ext = File.extname(path)
      ext[0] = '' if ext[0] == '.'
      ext.empty? ? nil : ext
    end

    def query
      url.query
    end

    def query_values
      url.query_values.to_h
    end

    def fragment
      url.fragment
    end

    def resource
      name = [
        [ segment, query ].compact.join('?'), fragment
      ].compact.join('#')
      name.empty? ? nil : name
    end

    def relative?
      url.relative?
    end

    def absolute?
      url.absolute?
    end

    def localhost?
      !!(hostname =~ /(\A|\.)localhost\z/)
    end

    private

    def slice_domain
      parser.subdomain.tap{ |s| s.slice!(domain) }
    end

    def tag_errors
      yield
    rescue Exception => error
      error.extend(UrlParser::Error)
      raise
    end

  end

end
