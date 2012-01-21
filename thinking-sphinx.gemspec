# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'thinking_sphinx/version'

Gem::Specification.new do |s|
  s.name        = 'thinking-sphinx'
  s.version     = ThinkingSphinx::Version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Pat Allan']
  s.email       = ['pat@freelancing-gods.com']
  s.homepage    = 'http://freelancing-god.github.com/ts/en/'
  s.summary     = %q{ActiveRecord/Rails Sphinx library}
  s.description = %q{A concise and easy-to-use Ruby library that connects ActiveRecord to the Sphinx search daemon, managing configuration, indexing and searching.}

  s.rubyforge_project = 'thinking-sphinx'

  s.files         = `git ls-files -- {lib,rails}`.split("\n") +
    %w( LICENCE README.textile tasks/rails.rake )
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'activerecord', ['< 3.0.0', '>= 1.15.6']
  s.add_runtime_dependency 'after_commit', '>= 1.0.7'
  s.add_runtime_dependency 'riddle',       '>= 1.5.0'

  s.add_development_dependency 'cucumber',      '1.0.2'
  s.add_development_dependency 'faker',         '0.3.1'
  s.add_development_dependency 'rake',          '>= 0.9.2'
  s.add_development_dependency 'rspec',         '2.6.0'
  s.add_development_dependency 'will_paginate', '2.3.15'
  s.add_development_dependency 'yard',          '>= 0.7.2'

  s.post_install_message = %q{If you're upgrading, you should read this:
http://freelancing-god.github.com/ts/en/upgrading.html

}
end
