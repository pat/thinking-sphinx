source 'https://rubygems.org'

gemspec

# Until there's a version beyond 0.7.0
gem 'combustion',
  :git    => 'https://github.com/pat/combustion.git',
  :branch => 'master'

gem 'mysql2', '~> 0.3.12b4', :platform => :ruby
gem 'pg',     '~> 0.18.4',   :platform => :ruby

if RUBY_PLATFORM == 'java'
  gem 'jdbc-mysql',                          '5.1.35',    :platform => :jruby
  gem 'activerecord-jdbcmysql-adapter',      '>= 1.3.23', :platform => :jruby
  gem 'activerecord-jdbcpostgresql-adapter', '>= 1.3.23', :platform => :jruby
  gem 'activerecord', '>= 3.2.22'
end

if RUBY_VERSION.to_f <= 2.1
  gem 'rack', '~> 1.0'
  gem 'nokogiri', '1.6.8'
end
