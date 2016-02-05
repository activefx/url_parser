require 'forwardable'
require 'resolv'

module UrlParser
  class URI
    extend Forwardable

    LOCALHOST_REGEXP  = /(\A|\.)localhost\z/

    COMPONENTS = [
      :scheme,              # Top level URI naming structure / protocol.
      :username,            # Username portion of the userinfo.
      :user,                # Alias for #username.
      :password,            # Password portion of the userinfo.
      :userinfo,            # URI username and password for authentication.
      :hostname,            # Fully qualified domain name or IP address.
      :naked_hostname,      # Hostname without any ww? prefix.
      :port,                # Port number.
      :host,                # Hostname and port.
      :www,                 # The ww? portion of the subdomain.
      :tld,                 # Returns the top level domain portion, aka the extension.
      :top_level_domain,    # Alias for #tld.
      :extension,           # Alias for #tld.
      :sld,                 # Returns the second level domain portion, aka the domain part.
      :second_level_domain, # Alias for #sld.
      :domain_name,         # Alias for #sld.
      :trd,                 # Returns the third level domain portion, aka the subdomain part.
      :third_level_domain,  # Alias for #trd.
      :subdomains,          # Alias for #trd.
      :naked_trd,           # Any non-ww? subdomains.
      :naked_subdomain,     # Alias for #naked_trd.
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

    def_delegators :@model, *COMPONENTS

    def_delegator :'@model.parsed_domain', :labels

    attr_reader :input, :uri, :options

    def initialize(uri, options = {}, &blk)
      @input      = uri
      @options    = set_options(options, &blk)
      @block      = blk ? blk : block_builder
      @uri        = UrlParser::Parser.call(@input, @options, &@block)
      @model      = UrlParser::Model.new(@uri)
    end

    def unescaped?
      !!options[:unescape]
    end

    def parsed?
      true
    end

    def unembedded?
      !!options[:unembed]
    end

    def canonicalized?
      !!options[:canonicalize]
    end

    def normalized?
      !!options[:normalize]
    end

    def cleaned?
      !!options[:clean] || (
        unescaped?      &&
        parsed?         &&
        unembedded?     &&
        canonicalized?  &&
        normalized?
      )
    end

    def clean
      if cleaned?
        raw
      else
        UrlParser::Parser.call(@input, raw: true) { |uri| uri.clean! }
      end
    end

    # Cleans and converts into a naked hostname
    #
    def canonical
      opts = { default_scheme: scheme, raw: true }
      curi = naked_hostname + location

      UrlParser::Parser.call(curi, opts) { |uri| uri.clean! }
    end

    def clean?
      cleaned? || self.to_s == clean
    end

    def relative?
      uri.relative?
    end

    def absolute?
      uri.absolute?
    end

    def localhost?
      !!(hostname[LOCALHOST_REGEXP])
    end

    def ipv4
      hostname[Resolv::IPv4::Regex]
    end

    def ipv4?
      !!ipv4
    end

    def ipv6
      host[Resolv::IPv6::Regex]
    end

    def ipv6?
      !!ipv6
    end

    def ip_address?
      ipv4? || ipv6?
    end

    def naked?
      !localhost? && www.nil?
    end

    def raw
      uri.to_s
    end
    alias_method :to_s, :raw

    def sha1
      Digest::SHA1.hexdigest(raw)
    end
    alias_method :hash, :sha1

    # TODO:
    #   Comparing should consider http & https equivalent and
    #   use the naked hostname
    #
    def ==(uri)
      opts  = options.merge(raw: true)

      clean == UrlParser::Parser.call(uri, opts) { |uri| uri.clean! }
    end

    def +(uri)
      self.class.new(uri, options.merge({ base_uri: self.to_s}), &@block)
    end
    alias_method :join, :+

    # def valid?(context = nil)
    #   validations.each do |attribute, validation_options|
    #     singleton_class.class_eval { validates attribute, validation_options }
    #   end
    #   super(context)
    # end

    private

    def set_options(opts = {}, &blk)
      UrlParser::OptionSetter
        .new(opts, &blk)
        .to_hash
        .merge(raw: false)
    end

    def block_builder
      proc do |uri|
        if cleaned?
          uri.clean!
        else
          uri.unescape!     if unescaped?
          uri.parse!        if parsed?
          uri.unembed!      if unembedded?
          uri.canonicalize! if canonicalized?
          uri.normalize!    if normalized?
        end
      end
    end

  end
end
