# TTY::Pager
[![Gem Version](https://badge.fury.io/rb/tty-pager.svg)][gem]
[![Build Status](https://secure.travis-ci.org/peter-murach/tty-pager.svg?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/peter-murach/tty-pager/badges/gpa.svg)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/peter-murach/tty-pager/badge.svg)][coverage]
[![Inline docs](http://inch-ci.org/github/peter-murach/tty-pager.svg?branch=master)][inchpages]

[gem]: http://badge.fury.io/rb/tty-pager
[travis]: http://travis-ci.org/peter-murach/tty-pager
[codeclimate]: https://codeclimate.com/github/peter-murach/tty-pager
[coverage]: https://coveralls.io/r/peter-murach/tty-pager
[inchpages]: http://inch-ci.org/github/peter-murach/tty-pager

> Terminal output paging in a cross-platform way supporting all major ruby interpreters.

**TTY::Pager** provides independent terminal output paging component for [TTY](https://github.com/peter-murach/tty) toolkit.

## Installation

Add this line to your application's Gemfile:

    gem 'tty-pager'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tty-pager

## 1. Usage

The **TTY::Pager** on initialization will choose the best available pager out of `SystemPager`, `BasicPager` or `NullPager`. If paging is disabled then a `NullPager` is used and content is simply printed out to stdout, otherwise a check is performed to find system executable to perform pagination natively with `SystemPager`. However, if no system executable is found, a `BasicPager` is used which is a pure Ruby implementation that will work with any ruby interpreter.

```ruby
pager = TTY::Pager.new
```

Then to perform actual content pagination invoke `page` method with the content to paginate as the argument:

```ruby
pager.page("Very long text...")
```

If you want to use specific pager you can do so by invoking it directly

```ruby
pager = TTY::Pager::BasicPager.new
```

If you want to disable the pager pass the `:enabled` option:

```ruby
pager = TTY::Pager.new enabled: false
```

For the `BasicPager` you can also pass a `:prompt` option to change the page break text:

```ruby
prompt = -> (page_num) { output.puts "Page -#{page_num}- Press enter to continue" }
pager = TTY::Pager::BasicPager.new prompt: prompt
```

By default the `SystemPager` will check the `PAGER` environment variable, if not set it will try one of the `less`, `more`, `cat`, `pager`. Therefore, if you wish to set your prefered pager you can either set up your shell like so:

```bash
PAGER=less
export PAGER
```

or set `PAGER` in Ruby script:

```ruby
ENV['PAGER']='less'
```

## Contributing

1. Fork it ( https://github.com/peter-murach/tty-pager/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Copyright

Copyright (c) 2015 Piotr Murach. See LICENSE for further details.
