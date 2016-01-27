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

end
