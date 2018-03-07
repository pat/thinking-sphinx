---
layout: en
title: Testing
gem_version: v4
redirect_from: "/testing.html"
---

## Testing with Thinking Sphinx

Before you get caught up in the specifics of testing Thinking Sphinx using certain tools, it's worth noting that no matter what the approach, you'll need to turn off transactional fixtures and index your data after creating the appropriate records - otherwise you won't get any search results.

Also: make sure you have your test environment using a different port number in `config/thinking_sphinx.yml` (which you may need to create if you haven't already). If this isn't done, then you won't be able to run Sphinx in your development environment _and_ your tests at the same time (as they'll both want to use the same port for Sphinx).

{% highlight yaml %}
test:
  mysql41: 9307
{% endhighlight %}

* [Unit Tests and Specs](#unit_tests)
* [Integration/Acceptance Testing](#acceptance)

<h3 id="unit_tests">Unit Tests and Specs</h3>

It's recommended you stub out any search calls, as Thinking Sphinx should ideally only be used in integration testing (whether that be via straight RSpec or Test/Unit, or Capybara/Cucumber).

If your unit tests use factories or fixtures, you may wish to disable delta indexing: this can be done with `ThinkingSphinx::Deltas.suspend!` and can be subsequently re-enabled with `ThinkingSphinx::Deltas.resume!`

<h3 id="acceptance">Integration/Acceptance Testing</h3>

#### Real-time indices

Because updates to real-time indices happen within the context of your Ruby app, you can use transactional fixtures easily enough. Here's some example code for RSpec that only enables Sphinx for request specs (you may want to alter it to also be enabled for feature/integration specs):

{% highlight ruby %}
RSpec.configure do |config|
  # Transactional fixtures work with real-time indices
  config.use_transactional_fixtures = true

  config.before :each do |example|
    # Configure and start Sphinx for request specs
    if example.metadata[:type] == :request
      ThinkingSphinx::Test.init
      ThinkingSphinx::Test.start index: false
    end

    # Disable real-time callbacks if Sphinx isn't running
    ThinkingSphinx::Configuration.instance.settings['real_time_callbacks'] =
      (example.metadata[:type] == :request)
  end

  config.after(:each) do |example|
    # Stop Sphinx and clear out data after request specs
    if example.metadata[:type] == :request
      ThinkingSphinx::Test.stop
      ThinkingSphinx::Test.clear
    end
  end
end
{% endhighlight %}

However, if you're performing browser testing (headless or through Selenium), you'll need to disable transactional fixtures and use a tool like Database Cleaner.

#### Using non-transactional fixtures

To use Sphinx with transactional fixtures disabled, I recommend using Ben Mabey's [Database Cleaner](https://github.com/DatabaseCleaner/database_cleaner) and a configuration along the lines of the following (with any tests requiring Sphinx to be tagged with `:sphinx => true`):

{% highlight ruby %}
RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:each) do
    # Default to transaction strategy for all specs
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :sphinx => true) do
    # For tests tagged with Sphinx, use deletion (or truncation)
    DatabaseCleaner.strategy = :deletion
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end
end
{% endhighlight %}

The configuration above should be combined with either the appropriate real-time index setup (above) or SQL-backed index setup (below).

#### SQL-backed indices

Whenever you're using Sphinx and SQL-backed indices with your test suite, you also _need_ to turn transactional fixtures off. The reason for this is that while ActiveRecord can run all its operations within a single transaction, Sphinx doesn't have access to that, and so indexing will not include your transaction's changes. Configuration for this is covered above.

The next step is to make sure Sphinx is set up for each test. Here's an example of a file for RSpec that could live at `spec/support/sphinx.rb`:

{% highlight ruby %}
module SphinxHelpers
  def index
    ThinkingSphinx::Test.index
    # Wait for Sphinx to finish loading in the new index files.
    sleep 0.25 until index_finished?
  end

  def index_finished?
    Dir[Rails.root.join(ThinkingSphinx::Test.config.indices_location, '*.{new,tmp}*')].empty?
  end
end

RSpec.configure do |config|
  config.include SphinxHelpers, type: :feature

  config.before(:suite) do
    # Ensure sphinx directories exist for the test environment
    ThinkingSphinx::Test.init
    # Configure and start Sphinx, and automatically
    # stop Sphinx at the end of the test suite.
    ThinkingSphinx::Test.start_with_autostop
  end

  config.before(:each) do
    # Index data when running an acceptance spec.
    index if example.metadata[:js]
  end
end
{% endhighlight %}

Delta indexes (if you're using the default approach) will automatically update just like they do in a normal application environment, but a full index can be run by calling the `index` method.

If you need to manually process specific indexes, just use the `index` method, which defaults to all indexes unless you pass in specific names.

{% highlight ruby %}
ThinkingSphinx::Test.index # all indexes
ThinkingSphinx::Test.index 'article_core', 'article_delta'
{% endhighlight %}

`ThinkingSphinx::Test.init` accepts a single argument `suppress_delta_output` that defaults to true. Just pass in false instead if you want to see delta output (for debugging purposes),

If you don't want Sphinx running for all of your tests, you can wrap the code that needs Sphinx in a block called by `ThinkingSphinx::Test.run`, which will start up and stop Sphinx either side of the block:

{% highlight ruby %}
test "Searching for Articles" do
  ThinkingSphinx::Test.run do
    get :index
    assert [@article], assigns[:articles]
  end
end
{% endhighlight %}
