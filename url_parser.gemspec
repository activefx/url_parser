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
  spec.description   = %q{Combine PostRank-URI, Domainatrix, and other Ruby url parsing libraries into a common interface.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "domainatrix", "~> 0.0.11"
  spec.add_dependency "postrank-uri", "~> 1.0.18"
  spec.add_dependency "addressable"
end
