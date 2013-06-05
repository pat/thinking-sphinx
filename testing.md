---
layout: en
title: Testing
---

## Testing with Thinking Sphinx

Before you get caught up in the specifics of testing Thinking Sphinx using certain tools, it's worth noting that no matter what the approach, you'll need to turn off transactional fixtures and index your data after creating the appropriate records - otherwise you won't get any search results.

Also: make sure you have your test environment using a different port number in `config/thinking_sphinx.yml` (which you may need to create if you haven't already). If this isn't done, then you won't be able to run Sphinx in your development environment _and_ your tests at the same time (as they'll both want to use the same port for Sphinx).

{% highlight yaml %}
test:
  mysql41: 9307
{% endhighlight %}

(If you're using a version of Thinking Sphinx prior to 3.0, the setting should be `port` instead of `mysql41`, and goes in `config/sphinx.yml` instead.)

* [Unit Tests and Specs](#unit_tests)
* [Integration/Acceptance Testing](#acceptance)

<h3 id="unit_tests">Unit Tests and Specs</h3>

It's recommended you stub out any search calls, as Thinking Sphinx should ideally only be used in integration testing (whether that be via straight RSpec or Test/Unit, or Capybara/Cucumber).

<h3 id="acceptance">Integration/Acceptance Testing</h3>

Whenever you're using Sphinx with your test suite, you also _need_ to turn transactional fixtures off. The reason for this is that while ActiveRecord can run all its operations within a single transaction, Sphinx doesn't have access to that, and so indexing will not include your transaction's changes.

The added complication to this is that you'll probably want to clear all the data from your database between scenarios. Ben Mabey's [Database Cleaner](http://github.com/bmabey/database_cleaner) is the most common tool for this - but you could also manually delete everything from each model in your setup code:

{% highlight ruby %}
[Article, User].each do |model|
  model.delete_all
end
{% endhighlight %}

The next step is to make sure Sphinx is set up for each test. Here's an example of a file for RSpec that could live at `spec/support/sphinx.rb`:

{% highlight ruby %}
module SphinxHelpers
  def index
    ThinkingSphinx::Test.index
    # Wait for Sphinx to finish loading in the new index files.
    sleep 0.25 until index_finished?
  end

  def index_finished?
    Dir[Rails.root.join(ThinkingSphinx::Test.config.searchd_file_path, '*.{new,tmp}.*')].empty?
  end
end

RSpec.configure do |config|
  config.include SphinxHelpers, type: :request

  config.before(:suite) do
    # Ensure sphinx directories exist for the test environment
    ThinkingSphinx::Test.init
    # Configure and start Sphinx, and automatically
    # stop Sphinx at the end of the test suite.
    ThinkingSphinx::Test.start_with_autostop
  end

  config.before(:each) do
    # Index data when running an acceptance spec.
    ThinkingSphinx::Test.index if example.metadata[:js]
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
