require 'spec_helper'
require 'url_parser/null_object'

RSpec.describe UrlParser::NullObject do

  let(:instance) { described_class.new }

  it "responds to any method with nil" do
    expect(instance.some_random_method).to be_nil
  end

end
