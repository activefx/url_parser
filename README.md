# UrlParser

[![Gem Version](https://img.shields.io/gem/v/url_parser.svg?style=flat)](https://rubygems.org/gems/url_parser)

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
uri = UrlParser.parse('foo://username:password@ww2.foo.bar.example.com:123/hello/world/there.html?name=ferret#foo')

uri.class               #=> UrlParser::URI
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

### Parse

Parse takes the provided URI and breaks it down into its component parts. To see a full list components provided, see [URI Data Model](#uri-data-model). If you provide an instance of Addressable::URI, it will consider the URI already parsed.

```ruby
uri = UrlParser.parse('http://example.org/foo?bar=baz')
uri.class
#=> UrlParser::URI
```

Unembed, canonicalize, normalize, and clean all rely on parse.

### Unembed

Unembed searches the provided URI's query values for redirection urls. By default, it searches the `u` and `url` params, however you can configure custom params to search.

```ruby
uri = UrlParser.unembed('http://energy.gov/exit?url=https%3A//twitter.com/energy')
uri.to_s
#=> "https://twitter.com/energy"
```

With custom embedded params keys:

```ruby
uri = UrlParser.unembed('https://www.upwork.com/leaving?ref=https%3A%2F%2Fwww.example.com', embedded_params: [ 'u', 'url', 'ref' ])
uri.to_s
#=> "https://www.example.com/"
```

### Canonicalize

Canonicalize applies filters on param keys to remove common tracking params, attempting to make it easier to identify duplicate URIs. For a full list of params, see `db.yml`.

```ruby
uri = UrlParser.canonicalize('https://en.wikipedia.org/wiki/Ruby_(programming_language)?source=ABCD&utm_source=EFGH')
uri.to_s
#=> "https://en.wikipedia.org/wiki/Ruby_(programming_language)?"
```

### Normalize

Normalize standardizes paths, query strings, anchors, whitespace, hostnames, and trailing slashes.

```ruby
# Normalize paths
uri = UrlParser.normalize('http://example.com/a/b/../../')
uri.to_s
#=> "http://example.com/"

# Normalize query strings
uri = UrlParser.normalize('http://example.com/?')
uri.to_s
#=> "http://example.com/"

# Normalize anchors
uri = UrlParser.normalize('http://example.com/#test')
uri.to_s
#=> "http://example.com/"

# Normalize whitespace
uri = UrlParser.normalize('http://example.com/a/../? #test')
uri.to_s
#=> "http://example.com/"

# Normalize hostnames
uri = UrlParser.normalize("💩.la")
uri.to_s
#=> "http://xn--ls8h.la/"

# Normalize trailing slashes
uri = UrlParser.normalize('http://example.com/a/b/')
uri.to_s
#=> "http://example.com/a/b"
```

### Clean

Clean combines parsing, unembedding, canonicalization, and normalization into a single call. It is designed to provide a method for cross-referencing identical urls.

```ruby
uri = UrlParser.clean('http://example.com/a/../?url=https%3A//💩.la/&utm_source=google')
uri.to_s
#=> "https://xn--ls8h.la/"

uri = UrlParser.clean('https://en.wikipedia.org/wiki/Ruby_(programming_language)?source=ABCD&utm_source%3Danalytics')
uri.to_s
#=> "https://en.wikipedia.org/wiki/Ruby_(programming_language)"
```

## UrlParser::URI

Parsing a URI with UrlParser returns an instance of `UrlParser::URI`, with the following methods available:

### URI Data Model

```ruby
 * :scheme              # Top level URI naming structure / protocol.
 * :username            # Username portion of the userinfo.
 * :user                # Alias for #username.
 * :password            # Password portion of the userinfo.
 * :userinfo            # URI username and password for authentication.
 * :hostname            # Fully qualified domain name or IP address.
 * :naked_hostname      # Hostname without any ww? prefix.
 * :port                # Port number.
 * :host                # Hostname and port.
 * :www                 # The ww? portion of the subdomain.
 * :tld                 # Returns the top level domain portion, aka the extension.
 * :top_level_domain    # Alias for #tld.
 * :extension           # Alias for #tld.
 * :sld                 # Returns the second level domain portion, aka the domain part.
 * :second_level_domain # Alias for #sld.
 * :domain_name         # Alias for #sld.
 * :trd                 # Returns the third level domain portion, aka the subdomain part.
 * :third_level_domain  # Alias for #trd.
 * :subdomains          # Alias for #trd.
 * :naked_trd           # Any non-ww? subdomains.
 * :naked_subdomain     # Alias for #naked_trd.
 * :domain              # The domain name with the tld.
 * :subdomain           # All subdomains, include ww?.
 * :origin              # Scheme and host.
 * :authority           # Userinfo and host.
 * :site                # Scheme, userinfo, and host.
 * :path                # Directory and segment.
 * :segment             # Last portion of the path.
 * :directory           # Any directories following the site within the URI.
 * :filename            # Segment if a file extension is present.
 * :suffix              # The file extension of the filename.
 * :query               # Params and values as a string.
 * :query_values        # A hash of params and values.
 * :fragment            # Fragment identifier.
 * :resource            # Path, query, and fragment.
 * :location            # Directory and resource - everything after the site.
```

### Additional URI Methods

```ruby
uri = UrlParser.clean('#')
uri.unescaped?      #=> true
uri.parsed?         #=> true
uri.unembedded?     #=> true
uri.canonicalized?  #=> true
uri.normalized?     #=> true
uri.cleaned?        #=> true

# IP / localhost methods
uri.localhost?
uri.ip_address?
uri.ipv4?
uri.ipv6?
uri.ipv4 #=> returns IPv4 address if applicable
uri.ipv6 #=> returns IPv6 address if applicable

# UrlParser::URI#relative?
uri = UrlParser.parse('/')
uri.relative?
#=> true

# UrlParser::URI#absolute?
uri = UrlParser.parse('http://example.com/')
uri.absolute?
#=> true

# UrlParser::URI#clean - return a cleaned string
uri = UrlParser.parse('http://example.com/?utm_source=google')
uri.clean
#=> "http://example.com/"

# UrlParser::URI#canonical - cleans and strips the scheme and ww? subdomain
uri = UrlParser.parse('http://example.com/?utm_source%3Danalytics')
uri.canonical
#=> "//example.com/"

# Joining URIs
uri = UrlParser.parse('http://foo.com/zee/zaw/zoom.html')
joined_uri = uri + '/bar#id'
joined_uri.to_s
#=> "http://foo.com/bar#id"

# UrlParser::URI #raw / #to_s - return the URI as a string
uri = UrlParser.parse('http://example.com/')
uri.raw
#=> "http://example.com/"

# Compare URIs
# Taking into account the scheme:
uri = UrlParser.parse('http://example.com/a/../?')
uri == 'http://example.com/'
#=> true
uri == 'https://example.com/'
#=> false

# Ignoring the scheme:
uri =~ 'https://example.com/'
#=> true

# UrlParser::URI#valid? - checks if URI is absolute and domain is valid
uri = UrlParser.parse('http://example.qqq/')
uri.valid?
#=> false
```

## Configuration

### embedded_params

Set the params the unembed parser uses to search for embedded URIs. Default is `[ 'u', 'url ]`. Set to an empty array to disable unembedding.

```ruby
UrlParser.configure do |config|
  config.embedded_params = [ 'ref' ]
end

uri = UrlParser.unembed('https://www.upwork.com/leaving?ref=https%3A%2F%2Fwww.example.com')
uri.to_s
#=> "https://www.example.com/"
```

### default_scheme

Set a default scheme if one is not present. Can also be set to nil if there should not be a default scheme. Default is `'http'`.

```ruby
UrlParser.configure do |config|
  config.default_scheme = 'https'
end

uri = UrlParser.parse('example.com')
uri.to_s
#=> "https://example.com/"
```

### scheme_map

Replace scheme keys in the 'map' with the corresponding value. Useful for replacing invalid or outdated schemes. Default is an empty hash.

```ruby
UrlParser.configure do |config|
  config.scheme_map = { 'feed' => 'http' }
end

uri = UrlParser.parse('feed://feeds.feedburner.com/YourBlog')
uri.to_s
#=> "http://feeds.feedburner.com/YourBlog"
```

## TODO

* Extract URIs from text
* Enable custom rules for normalization, canonicaliztion, escaping, and extraction

## Contributing

1. Fork it ( https://github.com/[my-github-username]/url_parser/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
