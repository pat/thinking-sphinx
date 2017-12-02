appraise 'rails_3_2' do
  gem 'rails',  '~> 3.2.22.2'
  gem 'rack',   '~> 1.0', :platforms => [:ruby_20, :ruby_21]
end if RUBY_VERSION.to_f <= 2.3

appraise 'rails_4_0' do
  gem 'rails', '~> 4.0.13'
  gem 'rack',   '~> 1.0', :platforms => [:ruby_20, :ruby_21]
end if RUBY_VERSION.to_f <= 2.3

appraise 'rails_4_1' do
  gem 'rails', '~> 4.1.15'
  gem 'rack',  '~> 1.0', :platforms => [:ruby_20, :ruby_21]
end if RUBY_VERSION.to_f <= 2.3

appraise 'rails_4_2' do
  gem 'rails', '~> 4.2.6'
  gem 'rack',  '~> 1.0', :platforms => [:ruby_20, :ruby_21]
end if RUBY_VERSION.to_f <= 2.3

appraise 'rails_5_0' do
  gem 'rails', '~> 5.0.2'
  gem 'jdbc-mysql',                          '~> 5.1.36', :platform => :jruby
  gem 'activerecord-jdbcmysql-adapter',      '~> 50.0',   :platform => :jruby
  gem 'activerecord-jdbcpostgresql-adapter', '~> 50.0',   :platform => :jruby
end if RUBY_VERSION.to_f >= 2.2

appraise 'rails_5_1' do
  gem 'rails', '~> 5.1.0'
end if RUBY_VERSION.to_f >= 2.2 && RUBY_PLATFORM != 'java'

appraise 'rails_5_2' do
  gem 'rails',  '~> 5.2.0.beta2'
  gem 'mysql2', '~> 0.4.4', :platform => :ruby
  gem 'pg',     '~> 0.21',  :platform => :ruby
  gem 'joiner',
    :git    => 'https://github.com/pat/joiner.git',
    :branch => 'master'
end if RUBY_VERSION.to_f >= 2.2 && RUBY_PLATFORM != 'java'
