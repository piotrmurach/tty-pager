require_relative "lib/tty/pager/version"

Gem::Specification.new do |spec|
  spec.name          = "tty-pager"
  spec.version       = TTY::Pager::VERSION
  spec.authors       = ["Piotr Murach"]
  spec.email         = ["piotr@piotrmurach.com"]
  spec.summary       = %q{Terminal output paging in a cross-platform way supporting all major ruby interpreters.}
  spec.description   = %q{Terminal output paging in a cross-platform way supporting all major ruby interpreters.}
  spec.homepage      = "https://piotrmurach.github.io/tty"
  spec.license       = "MIT"
  if spec.respond_to?(:metadata=)
    spec.metadata = {
      "allowed_push_host" => "https://rubygems.org",
      "bug_tracker_uri"   => "https://github.com/piotrmurach/tty-pager/issues",
      "changelog_uri"     => "https://github.com/piotrmurach/tty-pager/blob/master/CHANGELOG.md",
      "documentation_uri" => "https://www.rubydoc.info/gems/tty-pager",
      "homepage_uri"      => spec.homepage,
      "source_code_uri"   => "https://github.com/piotrmurach/tty-pager"
    }
  end
  spec.files         = Dir["lib/**/*"]
  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.bindir        = "exe"
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.0.0"

  spec.add_dependency "tty-screen", "~> 0.7"
  spec.add_dependency "tty-which",  "~> 0.4"
  spec.add_dependency "strings",    "~> 0.1.8"
end
