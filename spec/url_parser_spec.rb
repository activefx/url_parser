require 'spec_helper'

RSpec.describe UrlParser do

  it "must be defined" do
    expect(UrlParser::VERSION).not_to be_nil
  end

  context ".new" do

    it "returns an instance of UrlParser::URI" do
      expect(described_class.new('http://example.com')).to be_a UrlParser::URI
    end

  end

end
