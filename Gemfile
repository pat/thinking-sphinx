source :rubygems

gemspec

gem 'rcov',       '0.9.8',     :platform => :mri_18

platforms :ruby do
  gem 'mysql2', '~> 0.2.11'
  gem 'pg',     '0.9.0'
end

platform :jruby do
  gem 'activerecord-jdbcmysql-adapter',      '~> 1.1.3'
  gem 'activerecord-jdbcpostgresql-adapter', '~> 1.1.3'
end
