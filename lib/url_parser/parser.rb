require 'addressable/uri'
require 'digest/sha1'

module UrlParser
  class Parser

    class << self

      def call(uri, options = {}, &blk)
        return nil unless uri

        parser = new(uri, options).tap do |uri|
          if block_given?
            yield uri
          else
            uri.parse!
          end
        end

        parser.raw? ? parser.raw : parser.uri
      end
      alias_method :parse, :call

    end

    attr_reader \
      :uri,
      :domain,
      :default_scheme,
      :embedded_params,
      :options

    def initialize(uri, options = {})
      @uri              = uri
      @domain           = nil
      @base_uri         = options.delete(:base_uri) { nil }
      @default_scheme   = options.delete(:default_scheme) {
                            UrlParser.configuration.default_scheme
                          }
      @embedded_params  = options.delete(:embedded_params) {
                            UrlParser.configuration.embedded_params
                          }
      @raw              = options.delete(:raw) { false }
      @options          = options
    end

    def base_uri
      (@base_uri ? @base_uri : uri).to_s
    end

    def raw?
      !!@raw
    end

    def set_default_scheme?
      !!@default_scheme
    end

    def unescape
      UrlParser.unescape(uri)
    end

    def unescape!
      @uri = unescape
    end

    def parse
      return uri if uri.is_a?(Addressable::URI)

      Addressable::URI.parse(base_uri).tap do |parsed_uri|
        parsed_uri.join!(uri) if @base_uri

        if options[:host]
          parsed_uri.host = options[:host]
        else
          parts     = parsed_uri.path.to_s.split(/[\/:]/)
          hostname  = parsed_uri.host || parts.first
          @domain   = UrlParser::Domain.new(hostname)
          if @domain.valid?
            parsed_uri.path = '/' +
              parts.drop(1).join('/') +
              parsed_uri.path[/(?<=\/).*(\/)\s*$/, 1].to_s
            parsed_uri.host = @domain.name
          end
        end

        if parsed_uri.host && !parsed_uri.scheme
          parsed_uri.scheme = default_scheme
        end if set_default_scheme?

        if parsed_uri.host && !domain
          @domain = UrlParser::Domain.new(hostname)
        end
      end
    end

    def parse!
      @uri = parse
    end

    def unembed
      original = parse

      param_keys = if embedded_params.empty?
        UrlParser.configuration.embedded_params
      else
        UrlParser.wrap(embedded_params)
      end

      candidates = original.query_values.select do |key, value|
        param_keys.include?(key) &&
        value =~ Addressable::URI::URIREGEX
      end.values if original.query_values

      embed = candidates.find do |candidate|
        parsed = Addressable::URI.parse(candidate)
        %w(http https).include?(parsed.scheme) && parsed.host
      end if candidates

      embed ? self.class.call(embed, raw: raw?) : original
    end
    alias_method :embedded, :unembed

    def unembed!
      @uri = unembed
    end
    alias_method :embedded!, :unembed!

    def normalize
      parse.tap do |uri|
        uri.path      = uri.path.squeeze('/')
        uri.path      = uri.path.chomp('/') if uri.path.size != 1
        uri.query     = nil if uri.query && uri.query.empty?
        uri.query     = uri.query.strip if uri.query
        uri.fragment  = nil

        uri.normalize!
      end
    end

    def normalize!
      @uri = normalize
    end

    def canonicalize
      parse.tap do |uri|
        matches_global_param = proc do |key, value|
          UrlParser::DB[:global].include?(key)
        end

        matches_host_based_param = proc do |key, value|
          UrlParser::DB[:hosts].find do |host, param|
            uri.host =~ Regexp.new(Regexp.escape(host)) && param.include?(key)
          end
        end

        uri.query_values = uri.query_values(Array).tap do |params|
          params.delete_if &matches_global_param
          params.delete_if &matches_host_based_param
        end if uri.query_values
      end
    end
    alias_method :c14n, :canonicalize

    def canonicalize!
      @uri = canonicalize
    end
    alias_method :c14n!, :canonicalize!

    def raw
      uri.to_s
    end

    def raw!
      @uri = raw
    end

    def sha1
      Digest::SHA1.hexdigest(raw)
    end
    alias_method :hash, :sha1

    def clean!
      unescape!
      parse!
      unembed!
      canonicalize!
      normalize!
      raw! if raw?
    end

    def ==(uri)
      opts  = options.merge(raw: false)
      one   = self.dup.tap { |uri| uri.clean! }
      two   = self.class.new(uri, opts).tap { |uri| uri.clean! }

      one.sha1 == two.sha1
    end

  end
end
