require 'spec_helper'

RSpec.describe UrlParser do

  it "must be defined" do
    expect(UrlParser::VERSION).not_to be_nil
  end

  context "configuration" do

    context ":embedded_params" do

      it "sets the unembed param keys" do
        described_class.configuration.embedded_params = [ 'ref' ]
        uri = UrlParser.unembed('https://www.upwork.com/leaving?ref=https%3A%2F%2Fwww.example.com')
        expect(uri.to_s).to eq 'https://www.example.com/'
        described_class.configuration.reset
      end

    end

    context ":default_scheme" do

      it "sets a default scheme if one is not present" do
        described_class.configuration.default_scheme = 'https'
        uri = UrlParser.parse('example.com')
        expect(uri.to_s).to eq 'https://example.com/'
        described_class.configuration.reset
      end

    end

    context ":scheme_map" do

      it "replaces scheme keys in the map with the corresponding value" do
        described_class.configuration.scheme_map = { 'feed' => 'http' }
        uri = UrlParser.parse('feed://feeds.feedburner.com/YourBlog')
        expect(uri.to_s).to eq 'http://feeds.feedburner.com/YourBlog'
        described_class.configuration.reset
      end

    end

  end

  context ".tag_errors" do

    it "tags StandardError exceptions" do
      expect{
        described_class.tag_errors{ raise StandardError }
      }.to raise_error UrlParser::Error
    end

    it "does not tag errors that do not inherit from StandardError", :disable_raise_error_warning do
      expect{
        described_class.tag_errors{ raise Exception }
      }.not_to raise_error UrlParser::Error
    end

  end

  context ".new" do

    it "is deprecated" do
      expect(described_class).to receive(:warn)
      described_class.new('http://example.com')
    end

    it "calls .parse" do
      expect(described_class).to receive(:warn)
      expect(described_class).to receive(:parse)
      described_class.new('http://example.com')
    end

  end

  context ".escape" do

    it "encodes a string" do
      expect(described_class.escape('id=1')).to eq 'id%3D1'
    end

    it "escapes spaces as %20" do
      expect(described_class.escape('id= 1')).to eq 'id%3D%201'
    end

  end

  context ".unescape" do

    it "decodes a string" do
      expect(described_class.unescape('id%3D1')).to eq 'id=1'
    end

    it "unescapes spaces" do
      expect(described_class.unescape('id%3D%201')).to eq 'id= 1'
    end

    context "accept improperly encoded strings" do

      it "by unencoding spaces in the query encoded as '+'" do
        expect(described_class.unescape('?id=+1')).to eq '?id= 1'
      end

      it "by unencoding spaces in the query encoded as '+'" do
        expect(described_class.unescape('?id%3D+1')).to eq '?id= 1'
      end

      it "by unencoding spaces in the query encoded as '%20'" do
        expect(described_class.unescape('?id=%201')).to eq '?id= 1'
      end

      it "but does not unencode '+' to spaces in paths" do
        expect(described_class.unescape('/foo+bar?id=foo+bar')).to eq '/foo+bar?id=foo bar'
      end

    end

  end

  context ".parse" do

    it "returns an instance of UrlParser::URI" do
      expect(described_class.parse('http://example.com')).to be_a UrlParser::URI
    end

  end

  context ".unembed" do

    it "returns an instance of UrlParser::URI" do
      expect(described_class.unembed('http://example.com')).to be_a UrlParser::URI
    end

    it "parses the URI with the :unembed option enabled" do
      expect(UrlParser::URI).to receive(:new).with('#', hash_including(unembed: true))
      described_class.unembed('#')
    end

  end

  context ".canonicalize" do

    it "returns an instance of UrlParser::URI" do
      expect(described_class.canonicalize('http://example.com')).to be_a UrlParser::URI
    end

    it "parses the URI with the :canonicalize option enabled" do
      expect(UrlParser::URI).to receive(:new).with('#', hash_including(canonicalize: true))
      described_class.canonicalize('#')
    end

  end

  context ".normalize" do

    it "returns an instance of UrlParser::URI" do
      expect(described_class.normalize('http://example.com')).to be_a UrlParser::URI
    end

    it "parses the URI with the :normalize option enabled" do
      expect(UrlParser::URI).to receive(:new).with('#', hash_including(normalize: true))
      described_class.normalize('#')
    end

  end

  context ".clean" do

    it "returns an instance of UrlParser::URI" do
      expect(described_class.clean('http://example.com')).to be_a UrlParser::URI
    end

    it "parses the URI with the :clean option enabled" do
      expect(UrlParser::URI).to receive(:new).with('#', hash_including(clean: true))
      described_class.clean('#')
    end

  end

  context ".wrap" do

    it "converts nil to an array" do
      expect(described_class.wrap(nil)).to eq([])
    end

  end

end
