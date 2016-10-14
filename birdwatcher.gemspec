# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'birdwatcher/version'

Gem::Specification.new do |spec|
  spec.name          = "birdwatcher"
  spec.version       = Birdwatcher::VERSION
  spec.authors       = ["Michael Henrikesn"]
  spec.email         = ["michenriksen@neomailbox.ch"]

  spec.summary       = %q{Data analysis and OSINT framework for Twitter}
  spec.homepage      = "https://github.com/michenriksen/birdwatcher"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|doc|img)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sequel", "~> 4.38"
  spec.add_dependency "pg", "~> 0.19.0"
  spec.add_dependency "twitter", "~> 5.16"
  spec.add_dependency "colorize", "~> 0.8.1"
  spec.add_dependency "thread", "~> 0.2.2"
  spec.add_dependency "httparty", "~> 0.14.0"
  spec.add_dependency "highline", "~> 1.7", ">= 1.7.8"
  spec.add_dependency "terminal-table", "~> 1.7", ">= 1.7.3"
  spec.add_dependency "tty-pager", "~> 0.4.0"
  spec.add_dependency "sentimental", "~> 1.4"
  spec.add_dependency "ruby-graphviz", "~> 1.2", ">= 1.2.2"
  spec.add_dependency "chronic", "~> 0.10.2"
  spec.add_dependency "magic_cloud", "~> 0.0.3"
  spec.add_dependency "cairo", "~> 1.15", ">= 1.15.2"
  spec.add_dependency "awesome_print", "~> 1.7"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
