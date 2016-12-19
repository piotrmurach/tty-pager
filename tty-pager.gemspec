# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tty/pager/version'

Gem::Specification.new do |spec|
  spec.name          = "tty-pager"
  spec.version       = TTY::Pager::VERSION
  spec.authors       = ["Piotr Murach"]
  spec.email         = [""]
  spec.summary       = %q{Terminal output paging in a cross-platform way supporting all major ruby interpreters.}
  spec.description   = %q{Terminal output paging in a cross-platform way supporting all major ruby interpreters.}
  spec.homepage      = "https://github.com/piotrmurach/tty-pager"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'tty-screen', '~> 0.5.0'
  spec.add_dependency 'tty-which',  '~> 0.2.0'
  spec.add_dependency 'verse',      '~> 0.5.0'

  spec.add_development_dependency 'bundler', '>= 1.5.0', '< 2.0'
end
