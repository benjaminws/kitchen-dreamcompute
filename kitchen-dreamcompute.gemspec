# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen/driver/dreamcompute_version'

Gem::Specification.new do |spec|
  spec.name          = 'kitchen-dreamcompute'
  spec.version       = Kitchen::Driver::DREAMCOMPUTE_VERSION
  spec.authors       = ['Benjamin W. Smith']
  spec.email         = ['benjaminwarfield@just-another.net']
  spec.description   = %q{A Test Kitchen Driver for Dreamcompute}
  spec.summary       = spec.description
  spec.homepage      = ''
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'test-kitchen', '~> 1.0.0.alpha.4'
  spec.add_dependency 'fog'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'cane'
  spec.add_development_dependency 'tailor'
  spec.add_development_dependency 'countloc'
end
