require 'spec_helper'

RSpec.describe UrlParser::URI do

  let(:ipv4) { described_class.new('http://192.168.1.1') }
  let(:ipv6) { described_class.new('http://ff02::1') }
  let(:localhost) { described_class.new('http://localhost:5000/some/path') }
  let(:relative_uri) { described_class.new('/some/path/to.html?name=example') }

  let(:instance) do
    described_class.new('foo://username:password@ww2.foo.bar.example.com:123/hello/world/there.html?name=ferret#foo')
  end

  context ".new" do

    it "does not accept the :raw option" do
      instance = described_class.new('http://example.com', raw: true)
      expect(instance.uri).to be_an Addressable::URI
    end

    it "requires a uri" do
      expect{ described_class.new }.to raise_error ArgumentError
    end

    it "sets the input uri from the first argument" do
      instance = described_class.new('http://example.com')
      expect(instance.input).to eq 'http://example.com'
    end

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
            'http://example.com/',
            'http://example.com///',
            'http://example.com/../?#',
            'http://example.com/a/../?',
            'http://example.com/a/../?utm_source%3Danalytics'
          ].each do |url|
            expect(described_class.new(url, clean: true).to_s)
              .to eq 'http://example.com/'
          end
        end

        it "does not clean the url by default" do
          expect(described_class.new('link.to/?a=b&utm_source=FeedBurner#stuff').to_s)
            .to eq 'http://link.to/?a=b&utm_source=FeedBurner#stuff'
        end

      end

    end

    context "unescaped?" do

      it "is false by default" do
        instance = described_class.new('http://example.com/path?id%3D1')
        expect(instance).not_to be_unescaped
        expect(instance.to_s).to eq 'http://example.com/path?id%3D1'
      end

      it "returns true if the :unescape option is enabled" do
        instance = described_class.new('http://example.com/path?id%3D1', unescape: true)
        expect(instance).to be_unescaped
        expect(instance.to_s).to eq 'http://example.com/path?id=1'
      end

    end

    context "parsed?" do

      it "is true by default" do
        instance = described_class.new('http://example.com/')
        expect(instance).to be_parsed
      end

      it "cannot be set to false" do
        instance = described_class.new('http://example.com/', parse: false)
        expect(instance).to be_parsed
      end

    end

    context "unembedded?" do

      it "is false by default" do
        instance = described_class.new('http://energy.gov/exit?url=https%3A//twitter.com/energy')
        expect(instance).not_to be_unembedded
        expect(instance.uri.to_s).to eq 'http://energy.gov/exit?url=https%3A//twitter.com/energy'
      end

      it "returns true if the :unembed option is enabled" do
        instance = described_class.new('http://energy.gov/exit?url=https%3A//twitter.com/energy', unembed: true)
        expect(instance).to be_unembedded
        expect(instance.uri.to_s).to eq 'https://twitter.com/energy'
      end

    end

    context "canonicalized?" do

      it "is false by default" do
        instance = described_class.new('https://wikipedia.org/?source=ABCD&utm_source=EFGH')
        expect(instance).not_to be_canonicalized
        expect(instance.to_s).to eq 'https://wikipedia.org/?source=ABCD&utm_source=EFGH'
      end

      it "returns true if the :canonicalize option is enabled" do
        instance = described_class.new('https://wikipedia.org/?source=ABCD&utm_source=EFGH', canonicalize: true)
        expect(instance).to be_canonicalized
        expect(instance.to_s).to eq 'https://wikipedia.org/?'
      end

    end

    context "normalized?" do

      it "is false by default" do
        instance = described_class.new('http://example.com/#test')
        expect(instance).not_to be_normalized
        expect(instance.to_s).to eq 'http://example.com/#test'
      end

      it "returns true if the :canonicalize option is enabled" do
        instance = described_class.new('http://example.com/#test', normalize: true)
        expect(instance).to be_normalized
        expect(instance.to_s).to eq 'http://example.com/'
      end

    end

    context "cleaned?" do

      it "is false by default" do
        instance = described_class.new('http://example.com/?utm_source=google')
        expect(instance).not_to be_cleaned
        expect(instance.uri.to_s).to eq 'http://example.com/?utm_source=google'
      end

      it "returns true if the :clean option is enabled" do
        instance = described_class.new('http://example.com/?utm_source=google', clean: true)
        expect(instance).to be_cleaned
        expect(instance.uri.to_s).to eq 'http://example.com/'
      end

    end

    {
      scheme: 'foo',
      username: 'username',
      user: 'username',
      password: 'password',
      userinfo: 'username:password',
      hostname: 'ww2.foo.bar.example.com',
      naked_hostname: 'foo.bar.example.com',
      port: 123,
      host: 'ww2.foo.bar.example.com:123',
      www: 'ww2',
      tld: 'com',
      top_level_domain: 'com',
      extension: 'com',
      sld: 'example',
      second_level_domain: 'example',
      domain_name: 'example',
      trd: 'ww2.foo.bar',
      third_level_domain: 'ww2.foo.bar',
      subdomains: 'ww2.foo.bar',
      naked_trd: 'foo.bar',
      naked_subdomain: 'foo.bar',
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

      it "delegates ##{method} to the model instance" do
        expect(instance.send(method)).to eq UrlParser::Model.new(instance.uri).send(method)
        expect(instance.send(method)).to eq expected_value # Sanity check
      end

    end

    it "delegates #labels to the model instance's parsed_domain" do
      expect(instance.labels).to eq [ "com", "example", "bar", "foo", "ww2" ]
    end

  end

  context "clean" do

    it "returns the raw URI if the URI was cleaned on initialization" do
      instance = described_class.new('http://example.com/?utm_source=google', clean: true)
      expect(instance.clean).to eq 'http://example.com/'
    end

    it "reparses the original URI if it was not cleaned" do
      instance = described_class.new('http://example.com/?utm_source=google')
      expect(instance.clean).to eq 'http://example.com/'
    end

  end

  context "#clean?" do

    it "returns true if the URI was cleaned on initialization" do
      instance = described_class.new('http://example.com/?utm_source=google', clean: true)
      expect(instance).to be_clean
    end

    it "returns true if the URI was already 'clean'" do
      instance = described_class.new('http://example.com/')
      expect(instance).to be_clean
    end

    it "returns false if the URI is not clean" do
      instance = described_class.new('http://example.com/?utm_source=google')
      expect(instance).not_to be_clean
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

    it "returns an instance of UrlParser::URI" do
      instance = described_class.new(link)
      expect(instance + '#').to be_a described_class
    end

    it "is aliased to #join" do
      instance = described_class.new(link)
      expect(instance.method(:join)).to eq instance.method(:+)
    end

  end

  context "#raw" do

    it "is alised to #to_s" do
      instance = described_class.new('http://example.com/')
      expect(instance.method(:to_s)).to eq instance.method(:raw)
    end

    it "returns a string of the URI" do
      instance = described_class.new('http://example.com/')
      expect(instance.raw).to be_a String
    end

  end

  context "#sha1" do

    let(:instance) { described_class.new('http://example.com/') }

    it "is aliased to #hash" do
      expect(instance.method(:sha1)).to eq instance.method(:hash)
    end

    it "returns a SHA1 hash representation of the raw uri" do
      expect(instance.sha1).to eq "9c17e047f58f9220a7008d4f18152fee4d111d14"
    end

  end

  context "#canonical" do

    it "cleans the uri" do
      instance = described_class.new('http://example.com/?utm_source%3Danalytics')
      expect(instance.canonical).to eq '//example.com/'
    end

    it "strips the scheme" do
      instance = described_class.new('https://example.com/')
      expect(instance.canonical).to eq '//example.com/'
    end

    it "normalizes the uri" do
      instance = described_class.new('http://example.com/../')
      expect(instance.canonical).to eq '//example.com/'
    end

    it "converts it into a naked domain" do
      instance = described_class.new('http://www.example.com/')
      expect(instance.canonical).to eq '//example.com/'
    end

    it "preserves the scheme" do
      instance = described_class.new('https://www.example.com/')
      expect(instance.canonical).to eq '//example.com/'
    end

  end

  context "#relative?" do

    it "returns true for relative URIs" do
      expect(relative_uri).to be_relative
    end

    it "returns false for absolute URIs" do
      expect(instance).not_to be_relative
    end

  end

  context "#absolute?" do

    it "returns true for absolute URIs" do
      expect(instance).to be_absolute
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

  context "#ipv4" do

    it "returns the value of the ipv4 address if present" do
      expect(ipv4.ipv4).to eq '192.168.1.1'
    end

    it "returns nil if an ipv4 address is not present" do
      expect(localhost.ipv4).to be_nil
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

    it "returns the value of the ipv6 address if present" do
      expect(ipv6.ipv6).to eq 'ff02::1'
    end

    it "returns nil if an ipv6 address is not present" do
      expect(localhost.ipv6).to be_nil
    end

  end

  context "#ipv6?" do

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

  context "#==" do

    it "is true if two URIs have the same SHA1" do
      expect(
        described_class.new('http://example.com/') == 'http://example.com'
      ).to be true
    end

    it "is false if two URIs do not have the same SHA1" do
      expect(
        described_class.new('http://example.com/') == 'http://example.org'
      ).to be false
    end

    it "cleans both URIs before comparing" do
      expect(
        described_class.new('http://example.com/?utm_source=google') ==
        'http://example.com/?utm_source=yahoo'
      ).to be true
    end

    it "compares two URIs with the :raw option enabled" do
      expect(
        described_class.new('http://example.com/?utm_source=google', raw: true) ==
        'http://example.com/?utm_source=yahoo'
      ).to be true
    end

    it "does not ignore scheme" do
      expect(
        described_class.new('http://example.com/') == 'https://example.com'
      ).to be false
    end

  end

  context "#=~" do

    it "ignores scheme with the :ignore_scheme option" do
      expect(
        described_class.new('http://example.com/') =~ 'https://example.com'
      ).to be true
    end

  end

  context "#valid?" do

    context "by default" do

      it "is true for absolute URIs" do
        expect(instance).to be_valid
      end

      it "is false for relative URIs" do
        expect(relative_uri).not_to be_valid
      end

      it "is true for IPv4 addresses" do
        expect(ipv4).to be_valid
      end

      it "is true for IPv6 addresses" do
        expect(ipv6).to be_valid
      end

      it "is false with a domain not on the public suffix list" do
        instance = described_class.new('http://example.qqq')
        expect(instance).not_to be_valid
      end

    end

  end

end
