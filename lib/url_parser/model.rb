module UrlParser
  class Model

    attr_reader :parsed_uri, :parsed_domain

    def initialize(uri, domain = nil)
      unless uri.is_a?(Addressable::URI)
        raise RequiresAddressableURI,
          "#{uri} must be an Addressable::URI"
      end

      unless domain.is_a?(UrlParser::Domain)
        raise RequiresUrlParserDomain,
          "#{domain} must be a UrlParser::Domain"
      end if domain

      @parsed_uri     = uri
      @parsed_domain  = domain || UrlParser::Domain.new(uri.hostname)
    end

    # Top level URI naming structure / protocol.
    #
    def scheme
      parsed_uri.scheme
    end

    # Username portion of the userinfo.
    #
    def username
      parsed_uri.user
    end
    alias_method :user, :username

    # Password portion of the userinfo.
    #
    def password
      parsed_uri.password
    end

    # URI username and password for authentication.
    #
    def userinfo
      parsed_uri.userinfo
    end

    # Fully qualified domain name or IP address.
    #
    def hostname
      parsed_uri.host
    end

    # Fully qualified domain name or IP address without ww? prefix.
    #
    def naked_hostname
      if www
        hostname.sub(/\A#{www}./, '')
      else
        hostname
      end
    end

    # Port number.
    #
    def port
      parsed_uri.port
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

    # Returns the top level domain portion, aka the extension.
    #
    def tld
      parsed_domain.tld
    end
    alias_method :top_level_domain, :tld
    alias_method :extension, :tld

    # Returns the second level domain portion, aka the domain part.
    #
    def sld
      parsed_domain.sld
    end
    alias_method :second_level_domain, :sld
    alias_method :domain_name, :sld

    # Returns the third level domain portion, aka the subdomain part.
    #
    def trd
      parsed_domain.trd
    end
    alias_method :third_level_domain, :trd
    alias_method :subdomains, :trd

    # Any non-ww? subdomains.
    #
    def naked_trd
      (trd && www) ? trd[/(?<=^#{www}\.).+/] : trd
    end
    alias_method :naked_subdomain, :naked_trd

    # The domain name with the tld.
    #
    def domain
      parsed_domain.domain
    end

    # All subdomains, include ww?.
    #
    def subdomain
      parsed_domain.subdomain
    end

    # Scheme and host.
    #
    def origin
      original_origin = parsed_uri.origin
      original_origin == "null" ? nil : original_origin
    end

    # Userinfo and host.
    #
    def authority
      parsed_uri.authority
    end

    # Scheme, userinfo, and host.
    #
    def site
      parsed_uri.site
    end

    # Directory and segment.
    #
    def path
      parsed_uri.path
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
      parsed_uri.query
    end

    # A hash of params and values.
    #
    def query_values
      parsed_uri.query_values.to_h
    end

    # Fragment identifier.
    #
    def fragment
      parsed_uri.fragment
    end

    # Path, query, and fragment.
    #
    def resource
      name = [ segment, query_string, fragment_string ].compact.join
      name.empty? ? nil : name
    end

    # Directory and resource - everything after the site.
    #
    def location
      if directory == '/'
        directory + resource.to_s
      else
        result = [ directory, resource ].compact.join('/')
        result.empty? ? nil : result
      end
    end

    private

    def query_string
      query ? "?#{query}" : nil
    end

    def fragment_string
      fragment ? "##{fragment}" : nil
    end

  end
end
