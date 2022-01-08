require 'ostruct'
require 'forwardable'
require 'public_suffix'

module UrlParser
  class Domain
    extend Forwardable

    VALID_LABEL = /^(?!\-)[a-z0-9\-]*(?!\-)$/i

    SUFFIX_DEFAULTS = {
      subdomain: nil,
      domain: nil,
      tld: nil,
      sld: nil,
      trd: nil,
      to_s: ''
    }

    attr_reader :original, :name

    attr_accessor :errors

    def_delegators :suffix, *SUFFIX_DEFAULTS.keys

    def initialize(name, options = {})
      @original   = name.to_s.downcase.chomp('.')
      @name       = normalize
      @errors     = []
      @validated  = false
    end

    def labels
      PublicSuffix::Domain.name_to_labels(name).reverse
    end

    def suffix
      @suffix = begin
        PublicSuffix.parse(name, default_rule: nil)
      rescue PublicSuffix::DomainInvalid
        self.errors << "'#{original}' is not a valid domain"
        OpenStruct.new(SUFFIX_DEFAULTS)
      end
    end

    def valid?
      validate unless @validated
      errors.empty?
    end

    private

    def normalize
      Addressable::IDNA.to_ascii(original)
    end

    def validate
      validate_labels
      validate_label_length
      validate_label_format
      validate_total_length
      validate_suffix

      @validated = true
    end

    def validate_labels
      if labels.count > 127
        self.errors << "exceeds 127 labels"
      end
    end

    # http://tools.ietf.org/html/rfc1034#section-3.1
    #
    def validate_label_length
      if labels.max_by(&:length).length > 63
        self.errors << "exceeds maximum label length of 63 characters"
      end unless labels.empty?
    end

    def validate_label_format
      if labels.any? { |label| !(label =~ VALID_LABEL) }
        self.errors << "contains invalid characters"
      end
    end

    # https://blogs.msdn.microsoft.com/oldnewthing/20120412-00/?p=7873/
    #
    def validate_total_length
      if name.length > 253
        self.errors << "exceeds 253 ASCII characters"
      end
    end

    def validate_suffix
      suffix
    end

  end
end
