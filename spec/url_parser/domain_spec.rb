require 'spec_helper'

RSpec.describe UrlParser::Domain do

  context ".new" do

    it "downcases the input" do
      instance = described_class.new('EXAMPLE.COM')
      expect(instance.original).to eq 'example.com'
    end

    it "removes the root label from absolute domains" do
      instance = described_class.new('example.com.')
      expect(instance.original).to eq 'example.com'
    end

    it "sets #original as the input string" do
      instance = described_class.new("💩.la")
      expect(instance.original).to eq "💩.la"
    end

    it "sets the name as a string containing only ASCII characters" do
      instance = described_class.new("💩.la")
      expect(instance.name).to eq "xn--ls8h.la"
    end

  end

  context "#labels" do

    it "returns an array of domain parts" do
      instance = described_class.new('www.my.example.com')
      expect(instance.labels).to eq(["com", "example", "my", "www"])
    end

  end

  context "#suffix" do

    it "when domain is valid, returns a PublicSuffix::Domain" do
      instance = described_class.new('my.example.com')
      expect(instance.suffix).to be_a PublicSuffix::Domain
    end

    it "with a PublicSuffix::Domain, a call to #to_s returns the domain" do
      instance = described_class.new('my.example.com')
      expect(instance.suffix.to_s).to eq 'my.example.com'
    end

    it "when domain is invalid, returns a OpenStruct" do
      instance = described_class.new('//')
      expect(instance.suffix).to be_a OpenStruct
    end

    it "when domain is invalid, a call to #to_s returns an empty string" do
      instance = described_class.new('//')
      expect(instance.suffix.to_s).to eq ''
    end

  end

  context "#tld" do

    it "when domain is valid, returns the top level domain" do
      instance = described_class.new('www.my.example.com')
      expect(instance.tld).to eq 'com'
    end

    it "when domain is invalid, returns nil" do
      instance = described_class.new('//')
      expect(instance.tld).to be_nil
    end

  end

  context "#sld" do

    it "when domain is valid, returns the second level domain" do
      instance = described_class.new('www.my.example.com')
      expect(instance.sld).to eq 'example'
    end

    it "when domain is invalid, returns nil" do
      instance = described_class.new('//')
      expect(instance.sld).to be_nil
    end

  end

  context "#trd" do

    it "when domain is valid, returns the third level domain" do
      instance = described_class.new('www.my.example.com')
      expect(instance.trd).to eq 'www.my'
    end

    it "when domain is invalid, returns nil" do
      instance = described_class.new('//')
      expect(instance.trd).to be_nil
    end

  end

  context "#valid?" do

    it "is false when containing invalid characters" do
      instance = described_class.new('my&example.com')
      expect(instance).not_to be_valid
      expect(instance.errors).to include "contains invalid characters"
    end

    it "is true with a valid suffix" do
      instance = described_class.new('example.co.uk')
      expect(instance).to be_valid
    end

    it "is false with an invalid suffix" do
      instance = described_class.new('//')
      expect(instance).not_to be_valid
      expect(instance.errors).to include "'//' is not a valid domain"
    end

    it "is true with 127 labels or less" do
      instance = described_class.new('.'*126+'com')
      expect(instance).to be_valid
    end

    it "is false when exceeding 127 labels" do
      instance = described_class.new('.'*127+'com')
      expect(instance).not_to be_valid
      expect(instance.errors).to include "exceeds 127 labels"
    end

    it "is true when no labels are greater than 63 characters" do
      instance = described_class.new('a'*63+'.com')
      expect(instance).to be_valid
    end

    it "is false with labels greater than 63 characters" do
      instance = described_class.new('a'*64+'.com')
      expect(instance).not_to be_valid
      expect(instance.errors).to include "exceeds maximum label length of 63 characters"
    end

    it "is true with 253 ASCII characters or less" do
      instance = described_class.new('a'*49+'.'+'b'*49+'.'+'c'*49+'.'+'d'*49+'.'+'e'*49+'.com')
      expect(instance).to be_valid
    end

    it "is true with 253 ASCII characters or less" do
      instance = described_class.new('a'*49+'.'+'b'*49+'.'+'c'*49+'.'+'d'*49+'.'+'e'*49+'.aero')
      expect(instance).not_to be_valid
      expect(instance.errors).to include "exceeds 253 ASCII characters"
    end

  end

end
