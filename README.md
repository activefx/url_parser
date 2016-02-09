# UrlParser

[![Gem Version](https://img.shields.io/gem/v/url_parser.svg?style=flat)](https://rubygems.org/gems/url_parser)
[![Build Status](https://img.shields.io/travis/activefx/url_parser.svg?style=flat)](http://travis-ci.org/activefx/url_parser)
[![Code Climate](https://img.shields.io/codeclimate/github/activefx/url_parser.svg?style=flat)](https://codeclimate.com/github/activefx/url_parser)
[![Test Coverage](https://img.shields.io/codeclimate/coverage/github/activefx/url_parser.svg?style=flat)](https://codeclimate.com/github/activefx/url_parser/coverage)
[![Dependency Status](https://gemnasium.com/activefx/url_parser.svg)](https://gemnasium.com/activefx/url_parser)

Extended URI capabilities built on top of Addressable::URI. Parse URIs into granular components, unescape encoded characters, extract embedded URIs, normalize URIs, handle canonical url generation, and validate domains. Inspired by [PostRank-URI](https://github.com/postrank-labs/postrank-uri) and [URI.js](https://github.com/medialize/URI.js).

## Installation

Add this line to your application's Gemfile:

    gem 'url_parser'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install url_parser

## Example

```ruby
uri = UrlParser.parse(foo://username:password@ww2.foo.bar.example.com:123/hello/world/there.html?name=ferret#foo'')

uri.scheme              #=> 'foo'
uri.username            #=> 'username'
uri.user                #=> 'username' # Alias for #username
uri.password            #=> 'password'
uri.userinfo            #=> 'username:password'
uri.hostname            #=> 'ww2.foo.bar.example.com'
uri.naked_hostname      #=> 'foo.bar.example.com'
uri.port                #=> 123
uri.host                #=> 'ww2.foo.bar.example.com:123'
uri.www                 #=> 'ww2'
uri.tld                 #=> 'com'
uri.top_level_domain    #=> 'com' # Alias for #tld
uri.extension           #=> 'com' # Alias for #tld
uri.sld                 #=> 'example'
uri.second_level_domain #=> 'example' # Alias for #sld
uri.domain_name         #=> 'example' # Alias for #sld
uri.trd                 #=> 'ww2.foo.bar'
uri.third_level_domain  #=> 'ww2.foo.bar' # Alias for #trd
uri.subdomains          #=> 'ww2.foo.bar' # Alias for #trd
uri.naked_trd           #=> 'foo.bar'
uri.naked_subdomain     #=> 'foo.bar' # Alias for #naked_trd
uri.domain              #=> 'example.com'
uri.subdomain           #=> 'ww2.foo.bar.example.com'
uri.origin              #=> 'foo://ww2.foo.bar.example.com:123'
uri.authority           #=> 'username:password@ww2.foo.bar.example.com:123'
uri.site                #=> 'foo://username:password@ww2.foo.bar.example.com:123'
uri.path                #=> '/hello/world/there.html'
uri.segment             #=> 'there.html'
uri.directory           #=> '/hello/world'
uri.filename            #=> 'there.html'
uri.suffix              #=> 'html'
uri.query               #=> 'name=ferret'
uri.query_values        #=> { 'name' => 'ferret' }
uri.fragment            #=> 'foo'
uri.resource            #=> 'there.html?name=ferret#foo'
uri.location            #=> '/hello/world/there.html?name=ferret#foo'
```


## Usage

TODO: Write usage instructions here

## TODO

* Enable custom rules for normalization, canonicaliztion, escaping, and extraction

## Contributing

1. Fork it ( https://github.com/[my-github-username]/url_parser/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
