# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'logger'
gem 'mysql2', '~> 0.5.0',  :platform => :ruby
gem 'pg',     '~> 0.18.4', :platform => :ruby

gem 'activerecord', '< 7' if RUBY_VERSION.to_f <= 2.4

if RUBY_PLATFORM == 'java'
  gem 'jdbc-mysql',                          '5.1.35',    :platform => :jruby
  gem 'activerecord-jdbcmysql-adapter',      '>= 1.3.23', :platform => :jruby
  gem 'activerecord-jdbcpostgresql-adapter', '>= 1.3.23', :platform => :jruby
  gem 'activerecord', '>= 3.2.22'
end
