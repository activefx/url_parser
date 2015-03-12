require 'spec_helper'
require 'url_parser/uri'

RSpec.describe UrlParser::URI do

  let(:ipv4) { described_class.new('http://192.168.1.1') }
  let(:ipv6) { described_class.new('http://ff02::1') }
  let(:localhost) { described_class.new('http://localhost:5000/some/path') }
  let(:relative_uri) { described_class.new('/some/path/to.html?name=example') }
  let(:absolute_uri) { described_class.new('foo://username:password@ww2.foo.bar.example.com:123/hello/world/there.html?name=ferret#foo') }
  let(:instance) { absolute_uri }

  context "#new" do

    it "requires a uri" do
      expect{ described_class.new }.to raise_error ArgumentError
    end

    it "sets the original uri from the first argument" do
      instance = described_class.new('http://example.com')
      expect(instance.original).to eq 'http://example.com'
    end

    {
      scheme: 'foo',
      username: 'username',
      password: 'password',
      userinfo: 'username:password',
      hostname: 'ww2.foo.bar.example.com',
      port: 123,
      host: 'ww2.foo.bar.example.com:123',
      www: 'ww2',
      tld: 'com',
      sld: 'example',
      trd: 'ww2.foo.bar',
      naked_trd: 'foo.bar',
      domain: 'example.com',
      subdomain: 'ww2.foo.bar.example.com',
      origin: 'foo://ww2.foo.bar.example.com:123',
      authority: 'username:password@ww2.foo.bar.example.com:123',
      site: 'foo://username:password@ww2.foo.bar.example.com:123',
      path: '/hello/world/there.html',
      segment: 'there.html',
      directory: '/hello/world',
      filename: 'there.html',
      suffix: 'html',
      query: 'name=ferret',
      query_values: { 'name' => 'ferret' },
      fragment: 'foo',
      resource: 'there.html?name=ferret#foo',
      location: '/hello/world/there.html?name=ferret#foo'
    }.each do |method, expected_value|

      it "assigns #{method} on initialization" do
        expect(instance.send(method)).to eq expected_value
      end

    end

    context "options" do

      it "are not required" do
        instance = described_class.new('http://example.com')
        expect(instance.options).to be_empty
      end

      it "sets any included options" do
        instance = described_class.new('http://example.com', some: 'option')
        expect(instance.options).to eq({ some: 'option' })
      end

      context ":clean" do

        it "when true cleans the url" do
          instance = described_class.new('link.to?a=b&utm_source=FeedBurner#stuff', clean: true)
          expect(instance.to_s).to eq 'http://link.to/?a=b'
        end

        it "when true it normalizes the url" do
          [
            'http://igvita.com/',
            'http://igvita.com///',
            'http://igvita.com/../?#',
            'http://igvita.com/a/../?',
            'http://igvita.com/a/../?utm_source%3Danalytics'
          ].each do |url|
            expect(described_class.new(url, clean: true).to_s)
              .to eq 'http://igvita.com/'
          end
        end

        it "does not clean the url by default" do
          expect(described_class.new('link.to/?a=b&utm_source=FeedBurner#stuff').to_s)
            .to eq 'http://link.to/?a=b&utm_source=FeedBurner#stuff'
        end

      end

    end

  end

  context "#relative?" do

    it "returns true for relative URIs" do
      expect(relative_uri).to be_relative
    end

    it "returns false for absolute URIs" do
      expect(absolute_uri).not_to be_relative
    end

  end

  context "#absolute?" do

    it "returns true for absolute URIs" do
      expect(absolute_uri).to be_absolute
    end

    it "returns false for relative URIs" do
      expect(relative_uri).not_to be_absolute
    end

  end

  context "#naked?" do

    it "is always false for localhost addresses" do
      expect(localhost).not_to be_naked
    end

    it "is false for uris with a ww? third level domain" do
      instance = described_class.new('http://www.example.com')
      expect(instance).not_to be_naked
    end

    it "is true for uris without a ww? third level domain" do
      instance = described_class.new('http://example.com')
      expect(instance).to be_naked
    end

  end

  context "#localhost?" do

    it "returns true for localhost addresses" do
      expect(localhost).to be_localhost
    end

    it "returns false for non-localhost addresses" do
      expect(instance).not_to be_localhost
    end

  end

  context "#ipv4?" do

    it "returns true for ipv4 addresses" do
      expect(ipv4).to be_ipv4
    end

    it "returns false for non-ipv4 addresses" do
      expect(ipv6).not_to be_ipv4
    end

  end

  context "#ipv6" do

    it "returns true for ipv6 addresses" do
      expect(ipv6).to be_ipv6
    end

    it "returns false for non-ipv6 addresses" do
      expect(ipv4).not_to be_ipv6
    end

  end

  context "#ip_address?" do

    it "returns true for ipv4 addresses" do
      expect(ipv4).to be_ip_address
    end

    it "returns true for ipv6 addresses" do
      expect(ipv6).to be_ip_address
    end

    it "returns false for URIs that are not ip addresses" do
      expect(instance).not_to be_ip_address
    end

  end

  context "#username" do

    it "is aliased to #user" do
      expect(instance.method(:user)).to eq instance.method(:username)
    end

  end

  context "#tld" do

    it "is aliased to #top_level_domain" do
      expect(instance.method(:top_level_domain)).to eq instance.method(:tld)
    end

    it "is aliased to #extension" do
      expect(instance.method(:extension)).to eq instance.method(:tld)
    end

  end

  context "#sld" do

    it "is aliased to #second_level_domain" do
      expect(instance.method(:second_level_domain)).to eq instance.method(:sld)
    end

    it "is aliased to #domain_name" do
      expect(instance.method(:domain_name)).to eq instance.method(:sld)
    end

  end

  context "#trd" do

    it "is aliased to #third_level_domain" do
      expect(instance.method(:third_level_domain)).to eq instance.method(:trd)
    end

    it "is aliased to #subdomains" do
      expect(instance.method(:subdomains)).to eq instance.method(:trd)
    end

  end

  context "#naked_trd" do

    it "is aliased to #naked_subdomain" do
      expect(instance.method(:naked_subdomain)).to eq instance.method(:naked_trd)
    end

  end

  # Thanks to http://stackoverflow.com/a/4864170
  #
  context "#+" do

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
        instance = described_class.new(link)
        expect((instance + relative_url).to_s).to eq expected_result
      end

    end

    it "is aliased to #join" do
      expect(instance.method(:join)).to eq instance.method(:+)
    end

  end

  context "#hash" do

    let(:link) { 'http://example.com/' }
    let(:instance) { described_class.new(link) }

    it "returns the SHA1 of the uri" do
      expect(instance.hash).to eq Digest::SHA1.hexdigest(link)
    end

  end

  context "#canonical" do

    it "cleans the uri" do
      instance = described_class.new('http://example.com/?utm_source%3Danalytics')
      expect(instance.canonical).to eq 'http://example.com/'
    end

    it "normalizes the uri" do
      instance = described_class.new('http://example.com/../')
      expect(instance.canonical).to eq 'http://example.com/'
    end

    it "converts it into a naked domain" do
      instance = described_class.new('http://www.example.com/')
      expect(instance.canonical).to eq 'http://example.com/'
    end

  end

  context "#valid?" do

    context "by default" do

      it "is true for absolute URIs" do
        expect(absolute_uri).to be_valid
      end

      it "is true for relative URIs" do
        expect(relative_uri).to be_valid
      end

      it "is true for IPv4 addresses" do
        expect(ipv4).to be_valid
      end

      it "is true for IPv6 addresses" do
        expect(ipv6).to be_valid
      end

    end

    context "with custom validations" do

      let(:instance) do
        described_class.new('http://example.com', tld: { inclusion: { in: %w(net org) } })
      end

      it "are used to determine validity" do
        instance.valid?
        expect(instance.errors[:tld]).to include "is not included in the list"
      end

      it "apply on a case by case basis" do
        instance.valid?
        another_instance = described_class.new('http://example.com')
        expect(another_instance).to be_valid
      end

    end

    context "with the public suffix validator" do

      it "is valid with a domain on the public suffix list" do
        instance = described_class.new('http://example.com', domain: { public_suffix: true })
        expect(instance).to be_valid
      end

      it "is invalid with a domain not on the public suffix list" do
        instance = described_class.new('http://example.qqq', domain: { public_suffix: true })
        expect(instance).not_to be_valid
      end

      it "is invalid if the domain is not present" do
        instance = described_class.new('/some/relative/path', domain: { public_suffix: true })
        expect(instance).not_to be_valid
      end

      it "does nothing when applied to irrelevant attributes" do
        instance = described_class.new('/some/relative/path', path: { public_suffix: true })
        expect(instance).to be_valid
      end

    end

  end

end
