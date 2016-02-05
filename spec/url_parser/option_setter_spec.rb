require 'spec_helper'

RSpec.describe UrlParser::OptionSetter do

  context "to_hash" do

    it "returns an empty hash if there were no options or block" do
      instance = described_class.new
      expect(instance.to_hash).to eq({})
    end

    it "bases the hash results on the original options" do
      instance = described_class.new(unescape: false)
      settings = instance.to_hash
      expect(settings).to eq unescape: false
    end

    it "overwrites option settings if a method was called" do
      blk = ->(uri) { uri.unescape! }
      instance = described_class.new(unescape: false, &blk)
      settings = instance.to_hash
      expect(settings).to eq unescape: true
    end

    it "converts an #unescape! call to an unescape: true setting" do
      blk = ->(uri) { uri.unescape! }
      instance = described_class.new(&blk)
      settings = instance.to_hash
      expect(settings).to eq unescape: true
    end

    it "converts an #unembed! call to an unembed: true setting" do
      blk = ->(uri) { uri.unembed! }
      instance = described_class.new(&blk)
      settings = instance.to_hash
      expect(settings).to eq unembed: true
    end

    it "converts a #canonicalize! call to a canonicalize: true setting" do
      blk = ->(uri) { uri.canonicalize! }
      instance = described_class.new(&blk)
      settings = instance.to_hash
      expect(settings).to eq canonicalize: true
    end

    it "converts a #normalize! call to a normalize: true setting" do
      blk = ->(uri) { uri.normalize! }
      instance = described_class.new(&blk)
      settings = instance.to_hash
      expect(settings).to eq normalize: true
    end

    it "converts a #clean! call to all true settings" do
      blk = ->(uri) { uri.clean! }
      instance = described_class.new(&blk)
      expect(instance).to receive :unescape!
      expect(instance).to receive :unembed!
      expect(instance).to receive :canonicalize!
      expect(instance).to receive :normalize!
      instance.to_hash
    end

    it "ignores undefined method calls" do
      blk = ->(uri) { uri.parse! }
      instance = described_class.new(&blk)
      expect{ instance.to_hash }.not_to raise_error
    end

  end

end
