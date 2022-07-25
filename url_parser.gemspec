# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'url_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "url_parser"
  spec.version       = UrlParser::VERSION
  spec.authors       = ["Matt Solt"]
  spec.email         = ["mattsolt@gmail.com"]
  spec.summary       = %q{Extended URI capabilities built on top of Addressable::URI. Extract, parse, unescape, normalize, canonicalize, and clean URIs and URLs.}
  spec.description   = %q{Extended URI capabilities built on top of Addressable::URI. Extract, parse, unescape, normalize, canonicalize, and clean URIs and URLs.}
  spec.homepage      = "https://github.com/activefx/url_parser"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_dependency "gem_config"
  spec.add_dependency "public_suffix", "< 6", ">= 4.0"
  spec.add_dependency "addressable", "< 4", ">= 2.8"
end
