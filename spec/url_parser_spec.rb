require 'spec_helper'

RSpec.describe UrlParser do

  it "must be defined" do
    expect(UrlParser::VERSION).not_to be_nil
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

  context ".parse" do

    it "returns an instance of UrlParser::URI" do
      expect(described_class.parse('http://example.com')).to be_a UrlParser::URI
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

end
