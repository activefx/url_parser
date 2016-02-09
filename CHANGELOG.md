v0.5.0 / 2016-02-05
======================

  * Updated README.md
  * Added CHANGELOG.md
  * Only tag errors that inherit from StandardError 
  * Deprecate UrlParser.new, is now UrlParser.parse 
  * Added UrlParser::URI#ipv4 and UrlParser::URI#ipv6 to return the actual values, if applicable 
  * Added [gem_config](https://github.com/krautcomputing/gem_config) for configurable library settings :embedded_params, :default_scheme, and :scheme_map, see README.md for usage 
  * Add UrlParser module functions .parse, .unembed, .normalize, .canonicalize, and .clean 
  * Add UrlParser::Domain to handle domain name validations
  * Add UrlParser .escape and .unescape to encode and decode strings
  * Add UrlParser::Parser class for unescaping, parsing, unembedding, canonicalization, normalization, and hashing URI strings
  * Add UrlParser::URI#naked_hostname to return the entire hostname without any ww? prefix
  * Refactored UrlParser::URI and UrlParser::Parser classes, see README.md for updated usage 
  * Added 'addressable' to gemspec
  * Remove 'naught' gem dependency 
  * Remove 'activemodel' gem dependency
  * Remove 'activesupport' gem dependency
  * Remove 'postrank-uri' gem dependency
