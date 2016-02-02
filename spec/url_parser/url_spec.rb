require 'spec_helper'

RSpec.describe UrlParser::Url do

  context ".new" do

    context "uri" do

      it "requires an argument" do
        expect{ described_class.new }.to raise_error ArgumentError
      end

      it "parses a string into an Addressable::URI" do
        uri = 'http://example.com'
        expect(described_class.new(uri).uri).to be_an Addressable::URI
      end

      it "parses a URI into an Addressable::URI" do
        uri = URI('http://example.com')
        expect(described_class.new(uri).uri).to be_an Addressable::URI
      end

      it "does not parse an object that is an existing Addressable::URI" do
        uri = Addressable::URI.parse 'http://example.com'
        expect(described_class.new(uri).uri).to eq uri
      end

    end

  end

end
