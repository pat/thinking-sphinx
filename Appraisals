appraise 'rails_3_2' do
  gem 'rails',  '~> 3.2.22.2'
  gem 'mysql2', '~> 0.3.10', :platform => :ruby
end if RUBY_VERSION.to_f <= 2.3

appraise 'rails_4_0' do
  gem 'rails',  '~> 4.0.13'
  gem 'mysql2', '~> 0.3.10', :platform => :ruby
end if RUBY_VERSION.to_f <= 2.3

appraise 'rails_4_1' do
  gem 'rails',  '~> 4.1.15'
  gem 'mysql2', '~> 0.3.13', :platform => :ruby
end if RUBY_VERSION.to_f <= 2.3

appraise 'rails_4_2' do
  gem 'rails',  '~> 4.2.6'
  gem 'mysql2', '~> 0.4.0', :platform => :ruby
end if RUBY_VERSION.to_f <= 2.3

appraise 'rails_5_0' do
  if RUBY_PLATFORM == "java"
    gem 'rails', '5.0.6'
  else
    gem 'rails', '~> 5.0.7'
  end

  gem 'mysql2', '~> 0.4.0', :platform => :ruby

  gem 'jdbc-mysql',                          '~> 5.1.36', :platform => :jruby
  gem 'activerecord-jdbcmysql-adapter',      '~> 50.0',   :platform => :jruby
  gem 'activerecord-jdbcpostgresql-adapter', '~> 50.0',   :platform => :jruby
end if RUBY_PLATFORM != "java" || ENV["SPHINX_VERSION"].to_f > 2.1

appraise 'rails_5_1' do
  gem 'rails',  '~> 5.1.0'
  gem 'mysql2', '~> 0.4.0', :platform => :ruby
end if RUBY_PLATFORM != 'java'

appraise 'rails_5_2' do
  gem 'rails',  '~> 5.2.0'
  gem 'mysql2', '~> 0.5.0', :platform => :ruby
  gem 'pg',     '~> 1.0',   :platform => :ruby
end if RUBY_PLATFORM != 'java'

appraise 'rails_6_0' do
  gem 'rails',  '~> 6.0.0.beta1'
  gem 'mysql2', '~> 0.5.0', :platform => :ruby
  gem 'pg',     '~> 1.0',   :platform => :ruby
end if RUBY_PLATFORM != 'java' && RUBY_VERSION.to_f >= 2.5
