require "postrank-uri"
require "url_parser/null_object"

module UrlParser
  class Parser

    attr_reader :errors, :uri, :uri_parser, :domain_name_parser

    def initialize(uri)
      @errors             = Hash.new { |hash, key| hash[key] = Array.new }
      @uri                = uri
      @uri_parser         = parse_uri
      @domain_name_parser = parse_domain_name
    end

    # Top level URI naming structure / protocol.
    #
    def scheme
      uri_parser.scheme
    end

    # Username portion of the userinfo.
    #
    def username
      uri_parser.user
    end
    alias_method :user, :username

    # Password portion of the userinfo.
    #
    def password
      uri_parser.password
    end

    # URI username and password for authentication.
    #
    def userinfo
      uri_parser.userinfo
    end

    # Fully qualified domain name or IP address.
    #
    def hostname
      uri_parser.host
    end

    # Port number.
    #
    def port
      uri_parser.port
    end

    # Hostname and port.
    #
    def host
      result = [ hostname, port ].compact.join(':')
      result.empty? ? nil : result
    end

    # The ww? portion of the subdomain.
    #
    def www
      trd.split('.').first.to_s[/www?\d*/] if trd
    end

    # Returns the Top Level Domain part, aka the extension.
    #
    def tld
      domain_name_parser.tld
    end
    alias_method :top_level_domain, :tld
    alias_method :extension, :tld

    # Returns the Second Level Domain part, aka the domain part.
    #
    def sld
      domain_name_parser.sld
    end
    alias_method :second_level_domain, :sld
    alias_method :domain_name, :sld

    # Returns the Third Level Domain part, aka the subdomain part.
    #
    def trd
      domain_name_parser.trd
    end
    alias_method :third_level_domain, :trd
    alias_method :subdomains, :trd

    # Any non-ww? subdomains.
    #
    def naked_trd
      trd[/(?<=^#{www}\.).+/] if trd
    end
    alias_method :naked_subdomain, :naked_trd

    # The domain name with the tld.
    #
    def domain
      domain_name_parser.domain
    end

    # All subdomains, include ww?.
    #
    def subdomain
      domain_name_parser.subdomain
    end

    # Scheme and host.
    #
    def origin
      original_origin = uri_parser.origin
      original_origin == "null" ? nil : original_origin
    end

    # Userinfo and host.
    #
    def authority
      uri_parser.authority
    end

    # Scheme, userinfo, and host.
    #
    def site
      uri_parser.site
    end

    # Directory and segment.
    #
    def path
      uri_parser.path
    end

    # Last portion of the path.
    #
    def segment
      (path =~ /\/\z/ ? nil : path.split('/').last) if path
    end

    # Any directories following the site within the URI.
    #
    def directory
      unless path.nil? || path.empty?
        parts = path.split('/')
        if parts.empty?
          '/'
        else
          parts.pop unless segment.to_s.empty?
          parts.unshift('') unless parts.first.to_s.empty?
          parts.compact.join('/')
        end
      end
    end

    # Segment if a file extension is present.
    #
    def filename
      segment.to_s[/.+\..+/]
    end

    # The file extension of the filename.
    #
    def suffix
      if path
        ext = File.extname(path)
        ext[0] = '' if ext[0] == '.'
        ext.empty? ? nil : ext
      end
    end

    # Params and values as a string.
    #
    def query
      uri_parser.query
    end

    # A hash of params and values.
    #
    def query_values
      uri_parser.query_values.to_h
    end

    # Fragment identifier.
    #
    def fragment
      uri_parser.fragment
    end

    # Path, query, and fragment.
    #
    def resource
      name = [
        [ segment, query ].compact.join('?'), fragment
      ].compact.join('#')
      name.empty? ? nil : name
    end

    # Directory and resource - everything after the site.
    #
    def location
      result = [ directory, resource ].compact.join('/')
      result.empty? ? nil : result
    end

    private

    def parse_uri
      begin
        PostRank::URI.parse(uri)
      rescue => e
        errors[:base] << e.message
        UrlParser::NullObject.new
      end
    end

    def parse_domain_name
      begin
        PublicSuffix.parse(hostname)
      rescue PublicSuffix::Error => e
        errors[:domain] << e.message
        UrlParser::NullObject.new
      end
    end

  end
end
