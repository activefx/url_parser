RSpec.configure do |c|
  c.around(:each, :disable_raise_error_warning) do |example|
    RSpec::Expectations.configuration.warn_about_potential_false_positives = false
    example.call
    RSpec::Expectations.configuration.warn_about_potential_false_positives = true
  end
end
