v0.5.0 / 2017-01-26
======================

  * Added CHANGELOG.md
  * Only tag errors that inherit from StandardError 
  * Deprecate UrlParser.new, is now UrlParser.parse 
  * Added UrlParser::URI#ipv4 and UrlParser::URI#ipv6 to return the actual values, if applicable 
  * Added [gem_config](https://github.com/krautcomputing/gem_config) for configurable library settings :default_scheme and :scheme_map, see README.md for usage 
  * Added [SimpleIDN](https://github.com/mmriis/simpleidn) for unicode to ASCII conversions 
  * Add UrlParser::Domain to handle domain name validations
