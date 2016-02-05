# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'url_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "url_parser"
  spec.version       = UrlParser::VERSION
  spec.authors       = ["Matt Solt"]
  spec.email         = ["mattsolt@gmail.com"]
  spec.summary       = %q{Combine PostRank-URI, Domainatrix, and other Ruby url parsing libraries into a common interface.}
  spec.description   = %q{Uses PostRank-URI to clean, Addressable to break into components, and Domainatrix to determine domain and subdomain.}
  spec.homepage      = "https://github.com/activefx/url_parser"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "guard-rspec"

  spec.add_dependency "gem_config", "~> 0.3"
  spec.add_dependency "public_suffix", "~> 1.0"
  spec.add_dependency "addressable", "~> 2.0"
end
