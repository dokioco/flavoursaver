# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flavour_saver/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["James Harton", "Simon Russell"]
  gem.email         = ["james@resistor.io", "simon@dokio.co"]
  gem.description   = %q{FlavourSaver is a pure-ruby implimentation of the Handlebars templating language}
  gem.summary       = %q{Handlebars.js without the .js}
  gem.homepage      = "http://jamesotron.github.com/FlavourSaver/"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "flavour_saver"
  gem.require_paths = ["lib"]
  gem.version       = FlavourSaver::VERSION

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec-core', '~> 3'
  gem.add_development_dependency 'rspec-mocks', '~> 3'
  gem.add_development_dependency 'rspec-expectations', '~> 3'

  gem.add_dependency 'rltk', '~> 2.2.1'
end
