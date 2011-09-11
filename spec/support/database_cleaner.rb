RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each) do
    if example.example_group_instance.class.metadata[:live]
      DatabaseCleaner.clean
    end
  end
end
