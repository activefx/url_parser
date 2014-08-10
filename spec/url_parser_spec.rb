require 'spec_helper'

describe UrlParser do

  let(:parser) { UrlParser.new(link, clean: true) }

  it "must be defined" do
    expect(UrlParser::VERSION).not_to be_nil
  end

  context "::call" do

    let(:link) { 'http://example.com/' }
    let(:text) { "there is a #{link} in here" }
    let(:extractor) { UrlParser.call(text, clean: true) }

    it "extracts urls from text into an array" do
      expect(extractor.collect(&:url).collect(&:to_s))
        .to include link
    end

    it "initializes each url with the parser" do
      expect(extractor.first).to be_a UrlParser::Base
    end

  end

  context "::new" do

    let(:link) { 'http://example.com/path' }

    it "initializes a parser with a url" do
      expect(parser.to_s).to eq link
    end

    it "adds http by default" do
      expect(UrlParser.new('example.com/path').to_s).to eq link
    end

    it "adds http to protocol-less urls" do
      expect(UrlParser.new('//example.com/path').to_s).to eq link
    end

    it "cannot initialize invalid urls" do
      expect(UrlParser.new('http:||bra.ziz').url).to be_nil
    end

    it "catches errors from invalid urls" do
      expect(UrlParser.new('http:||bra.ziz').errors).not_to be_empty
    end

    context "options" do

      context ":clean" do

        let(:link) { 'link.to?a=b&utm_source=FeedBurner#stuff' }

        it "when true cleans the url" do
          expect(parser.to_s).not_to eq parser.original_url
        end

        it "when true it normalizes the url" do
          [
            'http://igvita.com/',
            'http://igvita.com///',
            'http://igvita.com/../?#',
            'http://igvita.com/a/../?',
            'http://igvita.com/a/../?utm_source%3Danalytics'
          ].each do |url|
            expect(UrlParser.new(url, clean: true).to_s)
              .to eq 'http://igvita.com/'
          end
        end

        it "does not clean the url by default" do
          expect(UrlParser.new(link).to_s)
            .to eq PostRank::URI.parse(parser.original_url).to_s
        end

      end

      context ":raise_errors" do

        it "raises instead of catching errors" do
          expect{
            UrlParser.new('http:||bra.ziz', raise_errors: true)
          }.to raise_error
        end

        it "any errors raised inherit from UrlParser::Error" do
          expect{
            UrlParser.new('http:||bra.ziz', raise_errors: true)
          }.to raise_error UrlParser::Error
        end

      end

    end

  end

  context "#original_url" do

    let(:link) { 'link.to?a=b&utm_source=FeedBurner#stuff' }

    it "preserves the url input" do
      expect(parser.original_url).to eq link
    end

  end

  context "#url" do

    let(:link) { 'link.to?a=b&utm_source=FeedBurner#stuff' }

    it "returns a url" do
      expect(parser.url).to be_a Addressable::URI
    end

  end

  context "#schemes" do

    it "returns an array of allowed schemes" do
      parser = UrlParser.new('telnet://some.com', schemes: 'telnet')
      expect(parser.schemes).to be_an Array
    end

  end

  context "#parse" do

    let(:link) { 'link.to?a=b&utm_source=FeedBurner#stuff' }

    it "calls postrank-uri's parse function" do
      expect(PostRank::URI).to receive :parse
      UrlParser.new(link, clean: false)
    end

    it "tags errors when set to raise errors" do
      parser = UrlParser.new(link, clean: true, raise_errors: true)
      expect(PostRank::URI).to receive(:parse).and_raise(StandardError)
      expect{ parser.send(:parse, link) }.to raise_error UrlParser::Error
    end

  end

  context "#clean" do

    let(:link) { 'link.to?a=b&utm_source=FeedBurner#stuff' }

    it "calls postrank-uri's clean function" do
      expect(PostRank::URI).to receive :clean
      UrlParser.new(link, clean: true)
    end

    it "tags errors" do
      parser = UrlParser.new(link, clean: false, raise_errors: true)
      expect(PostRank::URI).to receive(:clean).and_raise(StandardError)
      expect{ parser.send(:clean, link) }.to raise_error UrlParser::Error
    end

  end

  context "#parser" do

    let(:link) { 'link.to?a=b&utm_source=FeedBurner#stuff' }

    it "calls postrank-uri's clean function" do
      expect(Domainatrix).to receive(:parse).with(parser.to_s)
      UrlParser.new(link, clean: true)
    end

    it "tags errors" do
      expect(Domainatrix).to receive(:parse).and_raise(StandardError)
      expect{
        UrlParser.new(link, clean: false, raise_errors: true)
      }.to raise_error UrlParser::Error
    end

  end

  context "#clean!" do

    let(:link) { 'link.to?a=b&utm_source=FeedBurner#stuff' }
    let(:parser) { UrlParser.new(link) }

    it "normalizes the url" do
      parser.clean!
      expect(parser.to_s).to eq 'http://link.to/?a=b'
    end

    it "resets the parser" do
      expect{
        parser.clean!
      }.to change{
        parser.parser
      }
    end

  end

  context "#to_s" do

    let(:link) { 'http://example.com/' }

    it "returns a string representation of the url" do
      expect(parser.to_s).to eq 'http://example.com/'
    end

  end

  context "#hash" do

    let(:link) { 'http://example.com/' }

    it "hashes the url string" do
      expect(parser.hash).to eq Digest::SHA1.hexdigest(link)
    end

  end

  context "#valid?" do

    it "returns true if there are no errors" do
      expect(UrlParser.new('http://example.com')).to be_valid
    end

    it "returns false if there are errors" do
      expect(UrlParser.new('http:||bra.ziz')).not_to be_valid
    end

  end

  # Thanks to http://stackoverflow.com/a/4864170
  #
  context "#join" do

    let(:link) { 'http://foo.com/zee/zaw/zoom.html' }

    it "properly combines a url and and relative url" do
      {
        'http://zork.com/'                 => 'http://zork.com/',
        'http://zork.com/#id'              => 'http://zork.com/#id',
        'http://zork.com/bar'              => 'http://zork.com/bar',
        'http://zork.com/bar#id'           => 'http://zork.com/bar#id',
        'http://zork.com/bar/'             => 'http://zork.com/bar/',
        'http://zork.com/bar/#id'          => 'http://zork.com/bar/#id',
        'http://zork.com/bar/jim.html'     => 'http://zork.com/bar/jim.html',
        'http://zork.com/bar/jim.html#id'  => 'http://zork.com/bar/jim.html#id',
        '/bar'                             => 'http://foo.com/bar',
        '/bar#id'                          => 'http://foo.com/bar#id',
        '/bar/'                            => 'http://foo.com/bar/',
        '/bar/#id'                         => 'http://foo.com/bar/#id',
        '/bar/jim.html'                    => 'http://foo.com/bar/jim.html',
        '/bar/jim.html#id'                 => 'http://foo.com/bar/jim.html#id',
        'jim.html'                         => 'http://foo.com/zee/zaw/jim.html',
        'jim.html#id'                      => 'http://foo.com/zee/zaw/jim.html#id',
        '../jim.html'                      => 'http://foo.com/zee/jim.html',
        '../jim.html#id'                   => 'http://foo.com/zee/jim.html#id',
        '../'                              => 'http://foo.com/zee/',
        '../#id'                           => 'http://foo.com/zee/#id',
        '#id'                              => 'http://foo.com/zee/zaw/zoom.html#id'
      }.each do |relative_url, expected_result|
        expect(parser.join(relative_url).to_s).to eq expected_result
      end

    end

  end

  # http://medialize.github.io/URI.js/about-uris.html
  #
  context "uri components" do

    let(:parser) { UrlParser.new(link, clean: false) }

    context "when all are present" do

      let(:link) do
        'https://username:password@ww2.foo.bar.example.com:123/hello/world/there.html?name=ferret#foo'
      end

      it { expect(parser.errors).to be_empty }
      it { expect(parser).to be_valid }
      it { expect(parser.scheme).to eq 'https' }
      it { expect(parser.username).to eq 'username' }
      it { expect(parser.password).to eq 'password' }
      it { expect(parser.userinfo).to eq 'username:password' }
      it { expect(parser.www).to eq 'ww2' }
      it { expect(parser.subdomain).to eq 'foo.bar' }
      it { expect(parser.subdomains).to eq 'ww2.foo.bar' }
      it { expect(parser.domain_name).to eq 'example' }
      it { expect(parser.domain).to eq 'example.com' }
      it { expect(parser.tld).to eq 'com' }
      it { expect(parser.hostname).to eq 'ww2.foo.bar.example.com' }
      it { expect(parser.port).to eq 123 }
      it { expect(parser.host).to eq 'ww2.foo.bar.example.com:123' }
      it { expect(parser.origin).to eq 'https://ww2.foo.bar.example.com:123' }
      it { expect(parser.authority).to eq 'username:password@ww2.foo.bar.example.com:123' }
      it { expect(parser.site).to eq 'https://username:password@ww2.foo.bar.example.com:123' }
      it { expect(parser.directory).to eq '/hello/world' }
      it { expect(parser.path).to eq '/hello/world/there.html' }
      it { expect(parser.segment).to eq 'there.html' }
      it { expect(parser.filename).to eq 'there.html' }
      it { expect(parser.suffix).to eq 'html' }
      it { expect(parser.query).to eq 'name=ferret' }
      it { expect(parser.query_values['name']).to eq 'ferret' }
      it { expect(parser.fragment).to eq 'foo' }
      it { expect(parser.resource).to eq 'there.html?name=ferret#foo' }
    end

    context "when none are present" do

      let(:link) { '/' }

      it { expect(parser.errors).to be_empty }
      it { expect(parser.scheme).to be_nil }
      it { expect(parser.username).to be_nil }
      it { expect(parser.password).to be_nil }
      it { expect(parser.userinfo).to be_nil }
      it { expect(parser.www).to be_nil }
      it { expect(parser.subdomain).to be_nil }
      it { expect(parser.subdomains).to be_nil }
      it { expect(parser.domain_name).to be_nil }
      it { expect(parser.domain).to be_nil }
      it { expect(parser.tld).to be_nil }
      it { expect(parser.hostname).to be_nil }
      it { expect(parser.port).to be_nil }
      it { expect(parser.host).to be_nil }
      it { expect(parser.origin).to be_nil }
      it { expect(parser.authority).to be_nil }
      it { expect(parser.site).to be_nil }
      it { expect(parser.directory).to eq '/' }
      it { expect(parser.path).to eq '/' }
      it { expect(parser.segment).to be_nil }
      it { expect(parser.filename).to eq 'index.html' }
      it { expect(parser.suffix).to be_nil }
      it { expect(parser.query).to be_nil }
      it { expect(parser.query_values['name']).to be_nil }
      it { expect(parser.fragment).to be_nil }
      it { expect(parser.resource).to be_nil }

    end

    context "when empty" do

      let(:link) { '' }

      it { expect(parser.errors).to be_empty }
      it { expect(parser.scheme).to be_nil }
      it { expect(parser.username).to be_nil }
      it { expect(parser.password).to be_nil }
      it { expect(parser.userinfo).to be_nil }
      it { expect(parser.www).to be_nil }
      it { expect(parser.subdomain).to be_nil }
      it { expect(parser.subdomains).to be_nil }
      it { expect(parser.domain_name).to be_nil }
      it { expect(parser.domain).to be_nil }
      it { expect(parser.tld).to be_nil }
      it { expect(parser.hostname).to be_nil }
      it { expect(parser.port).to be_nil }
      it { expect(parser.host).to be_nil }
      it { expect(parser.origin).to be_nil }
      it { expect(parser.authority).to be_nil }
      it { expect(parser.site).to be_nil }
      it { expect(parser.directory).to eq '/' }
      it { expect(parser.path).to eq '' }
      it { expect(parser.segment).to be_nil }
      it { expect(parser.filename).to eq 'index.html' }
      it { expect(parser.suffix).to be_nil }
      it { expect(parser.query).to be_nil }
      it { expect(parser.query_values['name']).to be_nil }
      it { expect(parser.fragment).to be_nil }
      it { expect(parser.resource).to be_nil }

    end

    context "when invalid" do

      let(:link) { 'http://#content-zone' }

      it { expect(parser.errors).not_to be_empty }
      it { expect(parser.scheme).to be_nil }
      it { expect(parser.username).to be_nil }
      it { expect(parser.password).to be_nil }
      it { expect(parser.userinfo).to be_nil }
      it { expect(parser.www).to be_nil }
      it { expect(parser.subdomain).to be_nil }
      it { expect(parser.subdomains).to be_nil }
      it { expect(parser.domain_name).to be_nil }
      it { expect(parser.domain).to be_nil }
      it { expect(parser.tld).to be_nil }
      it { expect(parser.hostname).to be_nil }
      it { expect(parser.port).to be_nil }
      it { expect(parser.host).to be_nil }
      it { expect(parser.origin).to be_nil }
      it { expect(parser.authority).to be_nil }
      it { expect(parser.site).to be_nil }
      it { expect(parser.directory).to be_nil }
      it { expect(parser.path).to be_nil }
      it { expect(parser.segment).to be_nil }
      it { expect(parser.filename).to be_nil }
      it { expect(parser.suffix).to be_nil }
      it { expect(parser.query).to be_nil }
      it { expect(parser.query_values['name']).to be_nil }
      it { expect(parser.fragment).to be_nil }
      it { expect(parser.resource).to be_nil }

    end

  end

  context "localhost?" do

    let(:link) { 'localhost:5000' }

    it "returns true for localhost" do
      expect(parser).to be_localhost
    end

  end

  context "#domain_name" do

    let(:link) { 'https://github.com/pauldix/domainatrix' }

    it "returns the domain name without the suffix" do
      expect(parser.domain_name).to eq 'github'
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

    it "returns all subdomains" do
      expect(parser.subdomain).to eq 'foo.bar'
    end

    it "returns nil if there is no subdomain" do
      url = UrlParser.new('https://github.com/')
      expect(url.subdomain).to be_nil
    end

    it "does not include www as part of the subdomain" do
      parser = UrlParser.new("http://www.energy.ca.gov/")
      expect(parser.subdomain).to eq 'energy'
    end

    it "does not include any variation of www as part of the subdomain" do
      [ 'ww2', 'www2', 'ww23', 'www23' ].each do |www|
        parser = UrlParser.new("http://#{www}.energy.ca.gov/")
        expect(parser.subdomain).to eq 'energy'
      end
    end

  end

end
