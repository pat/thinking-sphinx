# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'mysql2', '~> 0.3.12b4', :platform => :ruby
gem 'pg',     '~> 0.18.4',   :platform => :ruby

if RUBY_PLATFORM == 'java'
  gem 'jdbc-mysql',                          '5.1.35',    :platform => :jruby
  gem 'activerecord-jdbcmysql-adapter',      '>= 1.3.23', :platform => :jruby
  gem 'activerecord-jdbcpostgresql-adapter', '>= 1.3.23', :platform => :jruby
  gem 'activerecord', '>= 3.2.22'
end
