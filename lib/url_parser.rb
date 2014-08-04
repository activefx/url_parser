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

    # https://secure.wikimedia.org/wikipedia/en/wiki/URI_scheme
    MAJOR_SCHEMES = [
      'file', 'ftp', 'gopher', 'h323', 'hdl', 'http', 'https', 'imap', 'magnet',
      'mailto', 'mms', 'news', 'nntp', 'prospero', 'rsync', 'rtsp', 'rtspu',
      'sftp', 'shttp', 'sip', 'sips', 'snews', 'svn', 'svn+ssh', 'telnet',
      'wais',
      # Unofficial schemes
      'aim', 'callto', 'cvs', 'facetime', 'feed', 'git', 'gtalk', 'irc', 'ircs',
      'irc6', 'itms', 'mms', 'msnim', 'skype', 'ssh', 'smb', 'svn', 'ymsg', 'mvn'
    ]

    DEFAULT_SCHEMES = [
      'http', 'https', 'ftp', 'mailto', 'file', 'ssh', 'feed',
      'cvs', 'git', 'mvn', 'nntp', 'shttp', 'svn'
    ]

    attr_reader :url, :original_url

    def initialize(url, options = {})
      tag_errors do
        @schemes = options.fetch(:schemes) { DEFAULT_SCHEMES }
        @preserve = !!options[:preserve]
        @original_url = url
        @url = @preserve ? url : PostRank::URI.clean(url)
      end
    end

    def clean!
      @preserve = false
      @parser = nil
      @uri = nil
      @url = PostRank::URI.clean(url)
      self
    end

    def to_s
      url
    end

    def schemes
      Array.wrap(@schemes)
    end

    def uri
      tag_errors do
        @uri ||= Addressable::URI.parse(url) rescue nil
      end
    end

    def scheme
      uri.scheme if uri
    end

    def user
      uri.user if uri
    end

    def password
      uri.password if uri
    end

    def host
      uri.host if uri
    end

    def port
      uri.port if uri
    end

    def path
      uri.path if uri
    end

    def query
      uri.query if uri
    end

    def fragment
      uri.fragment if uri
    end

    def query_values
      uri ? uri.query_values.to_h : {}
    end

    def valid?
      return true if domain == 'localhost'
      return false if uri.nil?
      return false unless schemes.include?(scheme)
      return false unless host =~ /\./
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

    def join(relative_path)
      joined_url = Addressable::URI.join(url, relative_path).to_s
      UrlParser.new(joined_url, preserve: true)
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
