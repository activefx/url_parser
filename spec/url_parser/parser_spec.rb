require 'spec_helper'

RSpec.describe UrlParser::Parser do

  let(:url) { 'http://example.com/path' }

  context ".new" do

    it "sets #uri" do
      expect(described_class.new('#').uri).to eq '#'
    end

    it "sets options" do
      opts = { host: 'localhost' }
      expect(described_class.new('#', opts).options).to eq opts
    end

    context "by default" do

      it "uses the library configured embedded_params" do
        expect(described_class.new('#').embedded_params)
          .to eq UrlParser.configuration.embedded_params
      end

      it "does not return the raw uri" do
        expect(described_class.new('#')).not_to be_raw
      end

    end

    context "options" do

      it "accepts a :base_uri option" do
        expect(described_class.new('#', base_uri: 'http://example.com').base_uri)
          .to eq 'http://example.com'
      end

      it "accepts a :raw option" do
        expect(described_class.new('#', raw: true)).to be_raw
      end

      it "accepts an :embedded_params option" do
        expect(described_class.new('#', embedded_params: 'ref').embedded_params)
          .to eq 'ref'
      end

    end

  end

  context ".call" do

    it "is aliased to .parse" do
      expect(described_class.method(:call)).to eq described_class.method(:parse)
    end

    it "returns an Addressable::URI" do
      expect(described_class.call('#id')).to be_an Addressable::URI
    end

    it "returns nil if the uri argument is nil" do
      expect(described_class.call(nil)).to be_nil
    end

    it "uses the default scheme if only a host is present" do
      expect(described_class.call('//example.com').scheme).to eq 'http'
    end

    it "does not fail with host labels that exceed size limitations" do
      expect(described_class.call('a'*64+'.ca').host).to eq nil
    end

    %w(javascript mailto xmpp).each do |scheme|

      context "with host-less schemes" do

        let(:instance) { described_class.call("#{scheme}:void(0);") }

        it "sets the scheme for #{scheme} links" do
          expect(instance.scheme).to eq "#{scheme}"
        end

        it "sets the path for #{scheme} links" do
          expect(instance.path).to eq 'void(0);'
        end

      end

    end

    it "accepts a custom host" do
      expect(described_class.call('/path', host: 'localhost').to_s).to eq 'http://localhost/path'
    end

    context "with a block" do

      it "can call parser methods to modify the uri" do
        blk = ->(uri){ uri.unembed! }
        uri = described_class.call('http://energy.gov/exit?url=https%3A//twitter.com/energy', &blk)
        expect(uri).to eq described_class.call('https://twitter.com/energy')
      end

      it "accepts the :raw option" do
        expect(described_class.call('https://twitter.com/energy', raw: true))
          .to eq 'https://twitter.com/energy'
      end

    end

  end

  context "#parse" do

    let(:instance) { described_class.new(url) }

    it "returns a parsed Addressable::URI" do
      expect(instance.parse).to be_an Addressable::URI
    end

    it "joins URIs with a :base_uri option" do
      instance = described_class.new('/bar#id', base_uri: 'http://foo.com/zee/zaw/zoom.html')
      expect(instance.parse).to eq described_class.call('http://foo.com/bar#id')
    end

    it "does not changes the value of #uri" do
      expect{
        instance.parse
      }.not_to change{
        instance.uri
      }
    end

  end

  context ".parse!" do

    let(:instance) { described_class.new(url) }

    it "updates #uri with the the parsed Addressable::URI" do
      expect{
        instance.parse!
      }.to change{
        instance.uri
      }
    end

    it "is idempotent" do
      instance.parse!
      expect{
        instance.parse!
      }.not_to change{
        instance.uri
      }
    end

  end

  context ".unescape" do

    let(:instance) { described_class.new('http://example.com/path?id%3D1') }

    it "returns an unescaped string" do
      expect(instance.unescape).to eq 'http://example.com/path?id=1'
    end

    it "does not changes the value of #uri" do
      expect{
        instance.unescape
      }.not_to change{
        instance.uri
      }
    end

  end

  context ".unescape!" do

    let(:instance) { described_class.new('http://example.com/path?id%3D1') }

    it "updates #uri with the the unescaped string" do
      expect{
        instance.unescape!
      }.to change{
        instance.uri
      }
    end

    it "is idempotent" do
      instance.unescape!
      expect{
        instance.unescape!
      }.not_to change{
        instance.uri
      }
    end

  end

  context ".unembed" do

    it "extracts an embedded url from a 'u' param" do
      url = 'http://www.myspace.com/Modules/PostTo/Pages/?u=http%3A%2F%2Fexample.com%2Fnews'
      instance = described_class.new(url)
      expect(instance.unembed).to eq described_class.call('http://example.com/news')
    end

    it "extracts an embedded url from a 'url' param" do
      url = 'http://energy.gov/exit?url=https%3A//twitter.com/energy'
      instance = described_class.new(url)
      expect(instance.unembed).to eq described_class.call('https://twitter.com/energy')
    end

    it "accepts a custom embedded param key" do
      url = 'https://www.upwork.com/leaving?ref=https%3A%2F%2Fwww.solaraccreditation.com.au' +
            '%2Fconsumers%2Ffind-an-installer.html'
      instance = described_class.new(url, embedded_params: 'ref')
      expect(instance.unembed)
        .to eq described_class.call('https://www.solaraccreditation.com.au/consumers/find-an-installer.html')
    end

    it "accepts custom embedded param keys" do
      url = 'https://www.upwork.com/leaving?ref=https%3A%2F%2Fwww.solaraccreditation.com.au' +
            '%2Fconsumers%2Ffind-an-installer.html'
      instance = described_class.new(url, embedded_params: [ 'u', 'url', 'ref'])
      expect(instance.unembed)
        .to eq described_class.call('https://www.solaraccreditation.com.au/consumers/find-an-installer.html')
    end

  end

  context ".unembed!" do

    let(:instance) { described_class.new('http://energy.gov/exit?url=https%3A//twitter.com/energy') }

    it "updates #uri with the the unescaped string" do
      expect{
        instance.unembed!
      }.to change{
        instance.uri
      }
    end

    it "is idempotent" do
      instance.unembed!
      expect{
        instance.unembed!
      }.not_to change{
        instance.uri
      }
    end

  end

  context ".canonicalize" do

    let(:instance) { described_class.new('https://wikipedia.org/?source=ABCD&utm_source=EFGH') }

    it "returns a canonicalized Addressable::URI" do
      expect(instance.canonicalize).to eq Addressable::URI.parse('https://wikipedia.org/')
    end

    it "does not changes the value of #uri" do
      expect{
        instance.canonicalize
      }.not_to change{
        instance.uri
      }
    end

  end

  context "#canonicalize!" do

    let(:instance) { described_class.new('https://wikipedia.org/?source=ABCD&utm_source=EFGH') }

    it "updates #uri with the the unescaped string" do
      expect{
        instance.canonicalize!
      }.to change{
        instance.uri
      }
    end

    it "is idempotent" do
      instance.canonicalize!
      expect{
        instance.canonicalize!
      }.not_to change{
        instance.uri
      }
    end

  end

  context "#raw" do

    let(:instance) { described_class.new('https://example.com') }

    it "returns a string" do
      instance.parse!
      expect(instance.raw).to eq 'https://example.com/'
    end

    it "does not changes the value of #uri" do
      expect{
        instance.raw
      }.not_to change{
        instance.uri
      }
    end

  end

  context "#raw!" do

    let(:instance) { described_class.new('https://example.com') }

    before do
      instance.parse!
    end

    it "updates #uri with the the raw string" do
      expect{
        instance.raw!
      }.to change{
        instance.uri
      }
    end

    it "is idempotent" do
      instance.raw!
      expect{
        instance.raw!
      }.not_to change{
        instance.uri
      }
    end

  end

  context "#sha1" do

    let(:instance) { described_class.new('http://example.com') }

    it "is aliased to #hash" do
      expect(instance.method(:sha1)).to eq instance.method(:hash)
    end

    it "returns a SHA1 hash representation of the raw uri" do
      expect(instance.sha1).to eq "89dce6a446a69d6b9bdc01ac75251e4c322bcdff"
    end

  end
end
