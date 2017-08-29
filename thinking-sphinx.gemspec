# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'thinking-sphinx'
  s.version     = '3.4.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Pat Allan"]
  s.email       = ["pat@freelancing-gods.com"]
  s.homepage    = 'https://pat.github.io/thinking-sphinx/'
  s.summary     = 'A smart wrapper over Sphinx for ActiveRecord'
  s.description = %Q{An intelligent layer for ActiveRecord (via Rails and Sinatra) for the Sphinx full-text search tool.}
  s.license     = 'MIT'

  s.rubyforge_project = 'thinking-sphinx'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f|
    File.basename(f)
  }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'activerecord', '>= 3.1.0'
  s.add_runtime_dependency 'builder',      '>= 2.1.2'
  s.add_runtime_dependency 'joiner',       '>= 0.2.0'
  s.add_runtime_dependency 'middleware',   '>= 0.1.0'
  s.add_runtime_dependency 'innertube',    '>= 1.0.2'
  s.add_runtime_dependency 'riddle',       '>= 2.0.0'

  s.add_development_dependency 'appraisal',        '~> 1.0.2'
  s.add_development_dependency 'combustion',       '~> 0.7.0'
  s.add_development_dependency 'database_cleaner', '~> 1.6.0'
  s.add_development_dependency 'rspec',            '~> 3.6.0'
  s.add_development_dependency 'rspec-retry',      '~> 0.5.4'
end
