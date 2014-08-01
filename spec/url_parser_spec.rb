require 'spec_helper'

describe UrlParser do

  let(:parser) { UrlParser.new(link) }

  it "must be defined" do
    expect(UrlParser::VERSION).not_to be_nil
  end

  context "::call" do

    let(:link) { 'http://example.com/' }
    let(:text) { "there is a #{link} in here" }
    let(:extractor) { UrlParser.call(text) }

    it "extracts urls from text into an array" do
      expect(extractor.collect(&:url)).to include link
    end

    it "initializes each url with the parser" do
      expect(extractor.first).to be_a UrlParser::Base
    end

  end

  context "::new" do

    let(:link) { 'http://example.com/' }

    it "initializes a parser with a url" do
      expect(parser.url).to eq link
    end

    it "cannot initialize invalid urls" do
      expect{ UrlParser.new('http:||bra.ziz') }.to raise_error
    end

    it "adds http by default" do
      expect(UrlParser.new('example.com').url).to eq link
    end

    it "adds http to protocol-less urls" do
      expect(UrlParser.new('//example.com').url).to eq link
    end

    it "any errors raised inherit from UrlParser::Error" do
      expect{
        UrlParser.new('http:||bra.ziz')
      }.to raise_error UrlParser::Error
    end

  end

  context "#uri" do

    it "returns a parsed uri" do
      expect(UrlParser.new('http://example.com').uri).to be_a URI
    end

  end

  context "#valid?" do

    it "returns false if the url is invalid" do
      expect(UrlParser.new('bullshit')).not_to be_valid
    end

    it "returns false if the url scheme is not in the options" do
      expect(UrlParser.new('telnet://some.com')).not_to be_valid
    end

    it "returns true if the url scheme is in the options" do
      expect(UrlParser.new('telnet://some.com', schemes: ['telnet'])).to be_valid
    end

    it "returns true if the url is valid" do
      expect(UrlParser.new('http://example.com/')).to be_valid
    end

    it "returns true for localhost" do
      expect(UrlParser.new('localhost:5000')).to be_valid
    end

  end

  context "#url" do

    let(:link) { 'link.to?a=b&utm_source=FeedBurner#stuff' }

    it "returns a url" do
      expect(parser.url).to eq 'http://link.to/?a=b'
    end

    it "attempts to clean and normalize urls" do
      [
        'http://igvita.com/',
        'http://igvita.com///',
        'http://igvita.com/../?#',
        'http://igvita.com/a/../?',
        'http://igvita.com/a/../?utm_source%3Danalytics'
      ].each do |url|
        expect(UrlParser.new(url).url)
          .to eq 'http://igvita.com/'
      end
    end

  end

  context "#domain" do

    let(:link) { 'https://github.com/pauldix/domainatrix' }

    it "returns the domain name with suffix" do
      expect(parser.domain).to eq 'github.com'
    end

  end

  context "#subdomain" do

    let(:link) { 'http://foo.bar.pauldix.co.uk/asdf.html?q=arg' }

    it "returns all subdomains with suffix" do
      expect(parser.subdomain).to eq 'foo.bar.pauldix.co.uk'
    end

    it "returns only the domain if there is no subdomain" do
      url = UrlParser.new('https://github.com/')
      expect(url.subdomain).to eq 'github.com'
    end

    it "does not include www as part of the subdomain" do
      parser = UrlParser.new("http://www.energy.ca.gov/")
      expect(parser.subdomain).to eq 'energy.ca.gov'
    end

    it "does not include any variation of www as part of the subdomain" do
      [ 'ww2', 'www2', 'ww23', 'www23' ].each do |www|
        parser = UrlParser.new("http://#{www}.energy.ca.gov/")
        expect(parser.subdomain).to eq 'energy.ca.gov'
      end
    end

  end

end
