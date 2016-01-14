require "resolv"
require "active_support/core_ext/hash/slice"
require "active_model"
require "addressable/uri"
require "digest/sha1"
require "url_parser/validators/public_suffix"
require "url_parser/parser"

module UrlParser
  class URI
    include ActiveModel::Model

    LOCALHOST_REGEXP  = /(\A|\.)localhost\z/

    COMPONENTS = [
      :scheme,              # Top level URI naming structure / protocol.
      :username,            # Username portion of the userinfo.
      :password,            # Password portion of the userinfo.
      :userinfo,            # URI username and password for authentication.
      :hostname,            # Fully qualified domain name or IP address.
      :port,                # Port number.
      :host,                # Hostname and port.
      :www,                 # The ww? portion of the subdomain.
      :tld,                 # Returns the top level domain portion, aka the extension.
      :sld,                 # Returns the second level domain portion, aka the domain part.
      :trd,                 # Returns the third level domain portion, aka the subdomain part.
      :naked_trd,           # Any non-ww? subdomains.
      :domain,              # The domain name with the tld.
      :subdomain,           # All subdomains, include ww?.
      :origin,              # Scheme and host.
      :authority,           # Userinfo and host.
      :site,                # Scheme, userinfo, and host.
      :path,                # Directory and segment.
      :segment,             # Last portion of the path.
      :directory,           # Any directories following the site within the URI.
      :filename,            # Segment if a file extension is present.
      :suffix,              # The file extension of the filename.
      :query,               # Params and values as a string.
      :query_values,        # A hash of params and values.
      :fragment,            # Fragment identifier.
      :resource,            # Path, query, and fragment.
      :location             # Directory and resource - everything after the site.
    ]

    ALIASES = [
      :user,                # Alias for #username.
      :top_level_domain,    # Alias for #tld.
      :extension,           # Alias for #tld.
      :second_level_domain, # Alias for #sld.
      :domain_name,         # Alias for #sld.
      :third_level_domain,  # Alias for #trd.
      :subdomains,          # Alias for #trd.
      :naked_subdomain      # Alias for #naked_trd.
    ]

    attr_reader :options, :errors, :original, :parser

    attr_accessor *COMPONENTS

    alias_method :user, :username
    alias_method :top_level_domain, :tld
    alias_method :extension, :tld
    alias_method :second_level_domain, :sld
    alias_method :domain_name, :sld
    alias_method :third_level_domain, :trd
    alias_method :subdomains, :trd
    alias_method :naked_subdomain, :naked_trd

    def initialize(uri, options = {})
      @errors   = ActiveModel::Errors.new(self)
      @options  = options
      @original = uri
      @parser   = parse(uri)
      assign_components
    end

    def cleaned?
      !!(options.fetch(:clean) { false })
    end

    def relative?
      parser.relative?
    end

    def absolute?
      parser.absolute?
    end

    def localhost?
      !!(hostname =~ LOCALHOST_REGEXP)
    end

    def ipv4?
      !!(hostname =~ Resolv::IPv4::Regex)
    end

    def ipv6?
      !!(host =~ Resolv::IPv6::Regex)
    end

    def ip_address?
      ipv4? || ipv6?
    end

    def naked?
      !localhost? && www.nil?
    end

    def hash
      Digest::SHA1.hexdigest(self.to_s)
    end

    def to_s
      parser.to_s
    end

    def +(value)
      UrlParser::URI.new(Addressable::URI.join(self.to_s, value), options)
    end
    alias_method :join, :+

    # Cleans, normalizes, and converts into a naked domain, useful for comparing URIs.
    #
    def canonical
      cleaned_uri = if cleaned?
        parser.to_s
      else
        UrlParser::Parser.new(self.to_s, options.merge({ clean: true })).to_s
      end
      if www
        cleaned_uri.sub(/\A#{Regexp.escape(scheme)}:\/\/#{www}\./, "#{scheme}://")
      else
        cleaned_uri
      end
    end

    def ===(uri)
      if uri.respond_to?(:canonical)
        uri_string = uri.canonical
      else
        uri_string = UrlParser::URI.new(uri.to_s, options.merge({ clean: true })).canonical
      end
      canonical == uri_string
    end

    def ==(uri)
      return false unless uri.kind_of?(UrlParser::URI)
      canonical == uri.canonical
    end

    def valid?(context = nil)
      validations.each do |attribute, validation_options|
        singleton_class.class_eval { validates attribute, validation_options }
      end
      super(context)
    end

    private

    def all_attribute_methods
      COMPONENTS + ALIASES
    end

    def parse(uri)
      case uri.class
      when UrlParser::URI
        uri.parser
      when UrlParser::Parser
        uri
      else
        UrlParser::Parser.new(uri, options)
      end
    end

    def assign_components
      COMPONENTS.each do |component|
        self.public_send("#{component}=", parser.public_send(component))
      end
    end

    def validations
      options.slice(*all_attribute_methods)
    end

  end
end
