# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wifiddler/version'

Gem::Specification.new do |spec|
  spec.name          = "wifiddler"
  spec.version       = Wifiddler::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Greg Sterndale"]
  spec.email         = ["gsterndale@gmail.com"]
  spec.summary       = %q{Simple CLI to cycle OSX AirPort (Wi-Fi) off & on}
  spec.description   = %q{Cycle your AirPort off & on until it connects to a network}
  spec.homepage      = "http://github.com/gsterndale/wifiddler"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec",    "~> 2.1"

  # Release every merge to master as a prerelease
  spec.version = "#{spec.version}.pre#{ENV['TRAVIS_BUILD_NUMBER']}" if ENV['TRAVIS']
end
