module UrlParser
  class Url

    attr_reader :uri

    def initialize(uri, options = {})
      @uri        = UrlParser::Parser.call(uri, options)
    end

  end
end
