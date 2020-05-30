<div align="center">
  <a href="https://piotrmurach.github.io/tty" target="_blank"><img width="130" src="https://github.com/piotrmurach/tty/raw/master/images/tty.png" alt="tty logo" /></a>
</div>

# TTY::Pager [![Gitter](https://badges.gitter.im/Join%20Chat.svg)][gitter]

[![Gem Version](https://badge.fury.io/rb/tty-pager.svg)][gem]
[![Build Status](https://secure.travis-ci.org/piotrmurach/tty-pager.svg?branch=master)][travis]
[![Build status](https://ci.appveyor.com/api/projects/status/3auc1vi3mk5puqai?svg=true)][appveyor]
[![Maintainability](https://api.codeclimate.com/v1/badges/636da0d02231b7f3e50f/maintainability)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/github/piotrmurach/tty-pager/badge.svg)][coverage]
[![Inline docs](http://inch-ci.org/github/piotrmurach/tty-pager.svg?branch=master)][inchpages]

[gitter]: https://gitter.im/piotrmurach/tty
[gem]: http://badge.fury.io/rb/tty-pager
[travis]: http://travis-ci.org/piotrmurach/tty-pager
[appveyor]: https://ci.appveyor.com/project/piotrmurach/tty-pager
[codeclimate]: https://codeclimate.com/github/piotrmurach/tty-pager/maintainability
[coverage]: https://coveralls.io/github/piotrmurach/tty-pager
[inchpages]: http://inch-ci.org/github/piotrmurach/tty-pager

> A cross-platform terminal pager that works on all major Ruby interpreters.

**TTY::Pager** provides independent terminal pager component for [TTY](https://github.com/piotrmurach/tty) toolkit.

## Installation

Add this line to your application's Gemfile:

    gem 'tty-pager'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tty-pager


## Overview

The **TTY::Pager** will automatically choose the best available pager on a user's system. Failing to do so, it will fallback on a pure Ruby version that is guaranteed to work with any Ruby interpreter and on any platform.

## Contents

* [1. Usage](#1-usage)
* [2. API](#2-api)
  * [2.1 new](#21-new)
    * [2.1.1 :enabled](#211-enabled)
    * [2.1.2 :command](#212-command)
    * [2.1.3 :width](#213-width)
    * [2.1.4 :prompt](#214-prompt)
  * [2.2 page](#22-page)
  * [2.3 write](#23-write)
  * [2.4 try_write](#24-try_write)
  * [2.5 puts](#25-puts)
  * [2.6 close](#26-close)
  * [2.7 ENV](#27-env)

## 1. Usage

The **TTY::Pager** will pick the best paging mechanism available on your system when initialized:

```ruby
pager = TTY::Pager.new
```

Then to start paginating text call the `page` method with the content as the first argument:

```ruby
pager.page("Very long text...")
```

This will launch a pager in the background and wait until the user is done.

Alternatively, you can pass the `:path` keyword to specify a file path:

```ruby
pager.page(path: "/path/to/filename.txt")
```

If instead you'd like to paginate a long-running operation, you could use the block form of the pager:

```ruby
TTY::Pager.page do |pager|
  File.open("file_with_lots_of_lines.txt", "r").each_line do |line|
    # do some work with the line

    pager.write(line) # send it to the pager
  end
end
```

After block finishes, the pager is automatically closed.

For more control, you can translate the block form into separate `write` and `close` calls:

```ruby
begin
  pager = TTY::Pager.new

  File.open("file_with_lots_of_lines.txt", "r").each_line do |line|
    # do some work with the line

    pager.write(line) # send it to the pager
  end
rescue TTY::Pager::PagerClosed
  # the user closed the paginating tool
ensure
  pager.close
end
```

If you want to use a specific pager you can do so by invoking it directly:

```ruby
pager = TTY::Pager::BasicPager.new
# or
pager = TTY::Pager::SystemPager.new
# or
pager = TTY::Pager::NullPager.new
```

## 2. API

### 2.1 new

The `TTY::Pager` can be configured during initialization for terminal width, type of prompt when basic pager is invoked, and the pagination command to run.

For example, to disable a pager in CI you could do:

```ruby
pager = TTY::Pager.new(enabled: false)
````

#### 2.1.1 :enabled

If you want to disable the paging use the `:enabled` option set to `false`:

```ruby
pager = TTY::Pager.new(enabled: false)
```

This will directly print all the content to the standard output. If the output isn't a tty device, the pager will return the content directly to the caller.

#### 2.1.2 :command

To force `TTY::Pager` to always use a specific paging tool(s), use the `:command` option:

```ruby
TTY::Pager.new(command: "less -R")
```

The `:command` also accepts an array of pagers to use:

```ruby
pager = TTY::Pager.new(command: ["less -r", "more -r"])
```

If the provided pager command or commands don't exist on user's system, the pager will fallback automatically on a basic Ruby implementation.

To skip automatic detection of pager and always use a system pager do:

```ruby
TTY::Pager::SystemPager.new(command: "less -R")
```

#### 2.1.3 :width

Only the `BasicPager` allows you to wrap content at given terminal width:

```ruby
pager = TTY::Pager.new(width: 80)
```

This option doesn't affect the `SystemPager`.

To directly use `BasicPager` do:

```ruby
pager = TTY::Pager::BasicPager.new(width: 80)
```

#### 2.1.4 :prompt

To change the `BasicPager` page break prompt display, use the `:prompt` option:

```ruby
prompt = -> (page) { "Page -#{page_num}- Press enter to continue" }
pager = TTY::Pager.new(prompt: prompt)
```

### 2.2 page

To start paging use the `page` method. It can be invoked on an instance or a class.

The class-level `page` is a convenient shortcut. To page some text you only need to do:

```ruby
TTY::Pager.page("Some long text...")
````

You can also include extra initialization parameters. For example, if you prefer to use a specific command do this:

```ruby
TTY::Pager.page("Some long text...", command: "less -R")
````

The instance equivalent would be:

```ruby
pager = TTY::Pager.new(command: "less -R")
pager.page("Some long text...")
````

Apart from text, you can page file content by passing the `:path` option:

```ruby
TTY::Pager.page(path: "/path/to/filename.txt")
````

The final way is to use the class-level `page` with a block. After the block is done, the pager is automatically closed. For example, to read a file line by line with additional processing you could do:

```ruby
TTY::Pager.page do |pager|
  File.foreach("filename.txt") do |line|
    # do some work with the line

    pager.write(line) # write line to the pager
  end
end
```

The instance equivalent of the block version would be:

```ruby
pager = TTY::Pager.new
begin
  File.foreach("filename.txt") do |line|
    # do some work with the line

    pager.write(line) # write line to the pager
  end
rescue TTY::Pager::PagerClosed
ensure
  pager.close
end
```

### 2.3 write

To stream content to the pager use the `write` method.

```ruby
pager.write("Some text")
```

You can pass in any number of arguments:

```ruby
pager.write("one", "two", "three")
```

### 2.4 try_write

To check if a write has been successful use `try_write`:

```ruby
pager.try_write("Some text")
# => true
```

### 2.5 puts

To write a line of text and end it with a new line use `puts` call:

```ruby
pager.puts("Single line of content")
```

### 2.6 close

When you're done streaming content manually use `close` to finish paging.

All interactions with a pager can raise an exception for various reasons, so wrap your code using the following pattern:

```ruby
pager = TTY::Pager.new

begin
  # ... perform pager writes
rescue TTY::Pager::PagerClosed
  # the user closed the paginating tool
ensure
  pager.close
end
```

Alternatively use the class-level `page` call with a block to automatically close the pager:

```ruby
TTY::Pager.page do |pager|
  # ... perform pager writes
end
```

### 2.7 ENV

By default the `SystemPager` will check the `PAGER` environment variable. If the `PAGER` isn't set, the pager will try one of the searched commands like `less`, `more` or `pg`.

Therefore, if you wish to set your preferred pager you can either set up your shell like so:

```bash
PAGER=less -R
export PAGER
```

Or set `PAGER` in Ruby script:

```ruby
ENV["PAGER"]="less -R"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/piotrmurach/tty-pager. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

1. Fork it ( https://github.com/piotrmurach/tty-pager/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Code of Conduct

Everyone interacting in the TTY::Pager project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/piotrmurach/tty-pager/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) 2015 Piotr Murach. See LICENSE for further details.
