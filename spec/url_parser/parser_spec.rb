require 'spec_helper'
require 'url_parser/parser'

RSpec.describe UrlParser::Parser do

  let(:invalid_input) { Array.new }
  let(:empty_uri) { '' }
  let(:root_path) { '/' }
  let(:relative_uri) { '/some/path/to.html?name=example' }
  let(:absolute_uri) { 'foo://username:password@ww2.foo.bar.example.com:123/hello/world/there.html?name=ferret#foo' }
  let(:ip_address) { 'http://127.0.0.1:80' }
  let(:ip_address_instance) { described_class.new(ip_address) }

  context ".new" do

    let(:example) { 'http://example.com' }

    it "requires an argument" do
      expect{ described_class.new }.to raise_error ArgumentError
    end

    it "accepts a string" do
      instance = described_class.new(example)
      expect(instance.sld).to eq 'example'
    end

    it "accepts a URI" do
      instance = described_class.new(URI(example))
      expect(instance.sld).to eq 'example'
    end

    it "accepts an Addressable::URI" do
      instance = described_class.new(Addressable::URI.parse(example))
      expect(instance.sld).to eq 'example'
    end

  end

  context "#errors" do

    let(:instance) { described_class.new(empty_uri) }

    it "provides an array for each key in the error hash" do
      instance.errors[:base] << 'error!'
      expect(instance.errors[:base]).to include 'error!'
    end

  end

  context "#respond_to?" do

    let(:instance) { described_class.new(empty_uri) }

    it "returns true for defined methods" do
      expect(instance).to respond_to :location
    end

    it "returns true for Addressable::URI instance methods" do
      expect(instance).to respond_to :relative?
    end

  end

  context "method missing" do

    let(:instance) { described_class.new(empty_uri) }

    it "deleages missing methods to Addressable::URI if available" do
      expect(instance.absolute?).to eq false
    end

  end

  context "DSL" do

    let(:instance) { described_class.new(absolute_uri) }

    context "#errors" do

      it "are empty when the URI and domain parse" do
        expect(instance.errors).to be_empty
      end

    end

    context "#scheme" do

      it "returns the top level URI protocol" do
        expect(instance.scheme).to eq 'foo'
      end

    end

    context "#username" do

      it "returns the username portion of the userinfo" do
        expect(instance.username).to eq 'username'
      end

      it "is aliased to #user" do
        expect(instance.method(:user)).to eq instance.method(:username)
      end

    end

    context "#password" do

      it "returns the password portion of the userinfo" do
        expect(instance.password).to eq 'password'
      end

    end

    context "#userinfo" do

      it "returns the URI username and password string for authentication" do
        expect(instance.userinfo).to eq 'username:password'
      end

    end

    context "#hostname" do

      it "returns the fully qualified domain name" do
        expect(instance.hostname).to eq 'ww2.foo.bar.example.com'
      end

      it "returns the fully qualified IP address" do
        expect(ip_address_instance.hostname).to eq '127.0.0.1'
      end

    end

    context "#port" do

      it "returns the port number" do
        expect(instance.port).to eq 123
      end

    end

    context "#host" do

      it "returns the hostname and port" do
        expect(instance.host).to eq 'ww2.foo.bar.example.com:123'
      end

    end

    context "#www" do

      it "returns the ww? portion of the subdomain" do
        expect(instance.www).to eq 'ww2'
      end

    end

    context "#tld" do

      it "returns the top level domain portion" do
        expect(instance.tld).to eq 'com'
      end

      it "is aliased to #top_level_domain" do
        expect(instance.method(:top_level_domain)).to eq instance.method(:tld)
      end

      it "is aliased to #extension" do
        expect(instance.method(:extension)).to eq instance.method(:tld)
      end

    end

    context "#sld" do

      it "returns the second level domain portion" do
        expect(instance.sld).to eq 'example'
      end

      it "is aliased to #second_level_domain" do
        expect(instance.method(:second_level_domain)).to eq instance.method(:sld)
      end

      it "is aliased to #domain_name" do
        expect(instance.method(:domain_name)).to eq instance.method(:sld)
      end

    end

    context "#trd" do

      it "returns the third level domain part" do
        expect(instance.trd).to eq 'ww2.foo.bar'
      end

      it "is aliased to #third_level_domain" do
        expect(instance.method(:third_level_domain)).to eq instance.method(:trd)
      end

      it "is aliased to #subdomains" do
        expect(instance.method(:subdomains)).to eq instance.method(:trd)
      end

    end

    context "#naked_trd" do

      it "returns any non-ww? subdomains" do
        expect(instance.naked_trd).to eq 'foo.bar'
      end

      it "is aliased to #naked_subdomain" do
        expect(instance.method(:naked_subdomain)).to eq instance.method(:naked_trd)
      end

      it "returns non-ww? subdomains when there is no ww? present" do
        instance = described_class.new('https://some.subdomain.example.com')
        expect(instance.naked_trd).to eq 'some.subdomain'
      end

    end

    context "#domain" do

      it "returns the domain name with the tld" do
        expect(instance.domain).to eq 'example.com'
      end

    end

    context "#subdomain" do

      it "returns all subdomains including ww?" do
        expect(instance.subdomain).to eq 'ww2.foo.bar.example.com'
      end

    end

    context "#origin" do

      it "returns the scheme and host" do
        expect(instance.origin).to eq 'foo://ww2.foo.bar.example.com:123'
      end

    end

    context "#authority" do

      it "returns the userinfo and host" do
        expect(instance.authority).to eq 'username:password@ww2.foo.bar.example.com:123'
      end

    end

    context "#site" do

      it "returns the scheme, userinfo, and host" do
        expect(instance.site).to eq 'foo://username:password@ww2.foo.bar.example.com:123'
      end

    end

    context "#path" do

      it "returns the directory and segment" do
        expect(instance.path).to eq '/hello/world/there.html'
      end

    end

    context "#segment" do

      it "returns the last portion of the path" do
        expect(instance.segment).to eq 'there.html'
      end

    end

    context "#directory" do

      it "returns any directories following the site within the URI" do
        expect(instance.directory).to eq '/hello/world'
      end

    end

    context "#filename" do

      it "returns the segment if a file extension is present" do
        expect(instance.filename).to eq 'there.html'
      end

      it "returns nil if a file extension is not present" do
        instance = described_class.new('/path/to/segment')
        expect(instance.filename).to be_nil
      end

    end

    context "#suffix" do

      it "returns the file extension of the filename" do
        expect(instance.suffix).to eq 'html'
      end

      it "returns nil if a file extension is not present" do
        instance = described_class.new('/path/to/segment')
        expect(instance.suffix).to be_nil
      end

    end

    context "#query" do

      it "returns the params and values as a string" do
        expect(instance.query).to eq 'name=ferret'
      end

    end

    context "#query_values" do

      it "returns a hash of params and values" do
        expect(instance.query_values).to eq({ 'name' => 'ferret' })
      end

    end

    context "#fragment" do

      it "returns the fragment identifier" do
        expect(instance.fragment).to eq 'foo'
      end

    end

    context "#resource" do

      it "returns the path, query, and fragment" do
        expect(instance.resource).to eq 'there.html?name=ferret#foo'
      end

    end

    context "#location" do

      it "returns the directory and resource, constituting everything after the site" do
        expect(instance.location).to eq '/hello/world/there.html?name=ferret#foo'
      end

    end

  end

  context "with a root path" do

    let(:instance) { described_class.new(root_path) }

    specify { expect(instance.errors[:base]).to be_empty }
    specify { expect(instance.errors[:domain]).not_to be_empty }

    specify { expect(instance.scheme).to be_nil }
    specify { expect(instance.username).to be_nil }
    specify { expect(instance.password).to be_nil }
    specify { expect(instance.userinfo).to be_nil }
    specify { expect(instance.hostname).to be_nil }
    specify { expect(instance.host).to be_nil }
    specify { expect(instance.port).to be_nil }
    specify { expect(instance.www).to be_nil }
    specify { expect(instance.tld).to be_nil }
    specify { expect(instance.sld).to be_nil }
    specify { expect(instance.trd).to be_nil }
    specify { expect(instance.naked_trd).to be_nil }
    specify { expect(instance.domain).to be_nil }
    specify { expect(instance.subdomain).to be_nil }
    specify { expect(instance.origin).to be_nil }
    specify { expect(instance.authority).to be_nil }
    specify { expect(instance.site).to be_nil }
    specify { expect(instance.path).to eq '/' }
    specify { expect(instance.segment).to be_nil }
    specify { expect(instance.directory).to eq '/' }
    specify { expect(instance.filename).to be_nil }
    specify { expect(instance.suffix).to be_nil }
    specify { expect(instance.query).to be_nil }
    specify { expect(instance.query_values).to eq({}) }
    specify { expect(instance.fragment).to be_nil }
    specify { expect(instance.resource).to be_nil }
    specify { expect(instance.location).to eq '/' }

  end

  context "with empty input" do

    let(:instance) { described_class.new(empty_uri) }

    specify { expect(instance.errors[:base]).to be_empty }
    specify { expect(instance.errors[:domain]).not_to be_empty }

    specify { expect(instance.scheme).to be_nil }
    specify { expect(instance.username).to be_nil }
    specify { expect(instance.password).to be_nil }
    specify { expect(instance.userinfo).to be_nil }
    specify { expect(instance.hostname).to be_nil }
    specify { expect(instance.host).to be_nil }
    specify { expect(instance.port).to be_nil }
    specify { expect(instance.www).to be_nil }
    specify { expect(instance.tld).to be_nil }
    specify { expect(instance.sld).to be_nil }
    specify { expect(instance.trd).to be_nil }
    specify { expect(instance.naked_trd).to be_nil }
    specify { expect(instance.domain).to be_nil }
    specify { expect(instance.subdomain).to be_nil }
    specify { expect(instance.origin).to be_nil }
    specify { expect(instance.authority).to be_nil }
    specify { expect(instance.site).to be_nil }
    specify { expect(instance.path).to eq '' }
    specify { expect(instance.segment).to be_nil }
    specify { expect(instance.directory).to be_nil }
    specify { expect(instance.filename).to be_nil }
    specify { expect(instance.suffix).to be_nil }
    specify { expect(instance.query).to be_nil }
    specify { expect(instance.query_values).to eq({}) }
    specify { expect(instance.fragment).to be_nil }
    specify { expect(instance.resource).to be_nil }
    specify { expect(instance.location).to be_nil }

  end

  context "with invalid input" do

    let(:instance) { described_class.new(invalid_input) }

    specify { expect(instance.errors[:base]).not_to be_empty }
    specify { expect(instance.errors[:domain]).not_to be_empty }

    specify { expect(instance.scheme).to be_nil }
    specify { expect(instance.username).to be_nil }
    specify { expect(instance.password).to be_nil }
    specify { expect(instance.userinfo).to be_nil }
    specify { expect(instance.hostname).to be_nil }
    specify { expect(instance.host).to be_nil }
    specify { expect(instance.port).to be_nil }
    specify { expect(instance.www).to be_nil }
    specify { expect(instance.tld).to be_nil }
    specify { expect(instance.sld).to be_nil }
    specify { expect(instance.trd).to be_nil }
    specify { expect(instance.naked_trd).to be_nil }
    specify { expect(instance.domain).to be_nil }
    specify { expect(instance.subdomain).to be_nil }
    specify { expect(instance.origin).to be_nil }
    specify { expect(instance.authority).to be_nil }
    specify { expect(instance.site).to be_nil }
    specify { expect(instance.path).to be_nil }
    specify { expect(instance.segment).to be_nil }
    specify { expect(instance.directory).to be_nil }
    specify { expect(instance.filename).to be_nil }
    specify { expect(instance.suffix).to be_nil }
    specify { expect(instance.query).to be_nil }
    specify { expect(instance.query_values).to eq({}) }
    specify { expect(instance.fragment).to be_nil }
    specify { expect(instance.resource).to be_nil }
    specify { expect(instance.location).to be_nil }

  end

end
