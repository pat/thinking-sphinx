source 'https://rubygems.org'

gemspec

gem 'mysql2', '~> 0.3.12b4', :platform => :ruby
gem 'pg',     '~> 0.18.4',   :platform => :ruby

gem 'jdbc-mysql',                          '5.1.35',   :platform => :jruby
gem 'activerecord-jdbcmysql-adapter',      '~> 1.3.23', :platform => :jruby
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.23', :platform => :jruby

if RUBY_VERSION.to_f <= 2.1
  gem 'rack', '~> 1.0'
  gem 'nokogiri', '1.6.8'
end
