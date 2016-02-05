module UrlParser
  class OptionSetter

    attr_reader :blk

    attr_accessor :options

    def initialize(options = {}, &blk)
      @options  = options
      @blk      = blk
    end

    def unescape!
      options[:unescape] = true
    end

    def unembed!
      options[:unembed] = true
    end

    def canonicalize!
      options[:canonicalize] = true
    end

    def normalize!
      options[:normalize] = true
    end

    def clean!
      unescape!
      unembed!
      canonicalize!
      normalize!
    end

    def to_hash
      blk.call(self) if blk
      self.options
    end
    alias_method :to_h, :to_hash

    def method_missing(*args)
      # no-op
    end

  end
end
