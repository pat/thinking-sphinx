# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'thinking_sphinx/version'

Gem::Specification.new do |s|
  s.name        = 'thinking-sphinx'
  s.version     = ThinkingSphinx::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Pat Allan"]
  s.email       = ["pat@freelancing-gods.com"]
  s.homepage    = 'http://freelancing-god.github.com/ts/en'
  s.summary     = 'A smart wrapper over Sphinx for ActiveRecord'
  s.description = %Q{An intelligent layer for ActiveRecord (via Rails and Sinatra) for the Sphinx full-text search tool.}

  s.rubyforge_project = 'thinking-sphinx'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f|
    File.basename(f)
  }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'activerecord', '>= 3.1.0'
  s.add_runtime_dependency 'builder',      '>= 2.1.2'
  s.add_runtime_dependency 'mysql2',       '>= 0.3.7'
  # s.add_runtime_dependency 'riddle',       '>= 1.5.0'

  s.add_development_dependency 'appraisal',        '~> 0.4.0'
  s.add_development_dependency 'combustion',       '~> 0.3.1'
  s.add_development_dependency 'database_cleaner', '~> 0.7.1'
  s.add_development_dependency 'rspec',            '~> 2.6.0'
end
