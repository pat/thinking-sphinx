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
  # gem 'activerecord-jdbc-adapter',
  #   :git      => 'git://github.com/jruby/activerecord-jdbc-adapter.git',
  #   :branch   => 'rails-5',
  #   :platform => :jruby,
  #   :ref      => 'c3570ce730'
end if RUBY_VERSION.to_f >= 2.2 && RUBY_PLATFORM != 'java'

appraise 'rails_5_1' do
  gem 'rails', '~> 5.1.0'
end if RUBY_VERSION.to_f >= 2.2 && RUBY_PLATFORM != 'java'
