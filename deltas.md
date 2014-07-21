---
layout: en
title: Delta Indexes
---

## Delta Indexes

Sphinx has one major limitation when compared to a lot of other search services: you cannot update the fields a single document in an index, but have to re-process all the data for that index.

The common approach around this issue, used by Thinking Sphinx, is the delta index - an index that tracks just the changed documents. Because this index is much smaller, it is super-fast to index.

To set this up in your web application, you need to do **3** things:

1. Add a delta column to your model
2. Turn on delta indexing for the index
3. Stop, re-index and restart Sphinx.

The first item on the list can be done via a migration, perhaps looking something like the following:

{% highlight ruby %}
def self.up
  add_column :articles, :delta, :boolean, :default => true,
    :null => false
end
{% endhighlight %}

Turning on delta indexing is done within your model's define_index block:

{% highlight ruby %}
ThinkingSphinx::Index.define :article, :with => :active_record, :delta => true do
  # ...
end
{% endhighlight %}

And finally, we need to rebuild the Sphinx indexes, as we have changed the structure of our Sphinx index setup.

{% highlight sh %}
rake ts:rebuild
{% endhighlight %}

Turning on delta indexing does not remove the need for regularly running a full re-index, as otherwise the delta index itself will grow to become just as large as the core indexes, and this removes the advantage of keeping it separate. It also slows down your requests to your server that make changes to the model records.

It's also worth noting that when each change happens, and the delta indexing is invoked, you will see the output from Sphinx's indexer tool either in your logs, or into your console. This serves as an indication that everything is working, but should you want to hide it, there's a global setting you can use in an initializer:

{% highlight rb %}
ThinkingSphinx.suppress_delta_output = true
{% endhighlight %}

<div class="note">
  <p><strong>Note</strong>: Sphinx requires local disk access to your index files to manage delta indices. This means that if you do shift delta processing to some sort of queue (such as Delayed Job, discussed below, or Resque), the queue workers will need to run on the same machine as Sphinx.</p>
</div>

### Deltas and Associations

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: This section has not yet been updated with details for Thinking Sphinx v3.</p>
</div>

If you are using associations for field or attribute data, delta indexing will not automatically happen when you make changes to those association models. You will need to add a manual delta hook to make it all update accordingly.

So, if we had the following field in an Article model:

{% highlight rb %}
indexes comments.content, :as => :comments
{% endhighlight %}

Then, in the Comment model, you'd want to have something like the following:

{% highlight rb %}
after_save :set_article_delta_flag
after_destroy :set_article_delta_flag

# ...

private

def set_article_delta_flag
  article.delta = true
  article.save
end
{% endhighlight %}

### Advanced Delta Approaches

One issue with the default delta approach, as outlined above, is that it creates a noticeable speed decrease on busy websites, because the delta indexing is run as part of each request that makes a change to the model records.

#### Timestamp/Datetime Deltas

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: This section has not yet been updated with details for Thinking Sphinx v3.</p>
</div>

There are two other delta approaches that Thinking Sphinx supports. The first is by using a timestamp column to track when changes have happened, and then run a rake task to index just those changes on a regular basis.

This functionality is in a separate gem, so you'll need to install it:

{% highlight sh %}
gem install ts-datetime-delta
{% endhighlight %}

And then add the details to your `environment.rb` file:

{% highlight ruby %}
config.gem 'ts-datetime-delta',
  :lib     => 'thinking_sphinx/deltas/datetime_delta',
  :version => '1.0.2'
{% endhighlight %}

For those of you using Rails 3, then your Gemfile is the place for this information:

{% highlight ruby %}
gem 'ts-datetime-delta', '1.0.2',
  :require => 'thinking_sphinx/deltas/datetime_delta'
{% endhighlight %}

And finally, make sure the rake tasks are available, by adding the following line to the end of your `Rakefile`:

{% highlight ruby %}
require 'thinking_sphinx/deltas/datetime_delta/tasks'
{% endhighlight %}

As for your models, no delta column is required for this method, and enabling it is done by the following code in the define_index block:

{% highlight ruby %}
define_index do
  # ...

  set_property :delta => :datetime, :threshold => 1.hour
end
{% endhighlight %}

This will use the `updated_at` column - if you wish to use a different column, specify it using the `:delta_column` option. The threshold value is important to note: this is how often you'll need to process the delta indexes via a rake task:

{% highlight sh %}
rake thinking_sphinx:index:delta
rake ts:in:delta # shortcut
{% endhighlight %}

It's actually best to set the threshold a bit higher than the occurance of the rake task (so in this example, maybe the threshold should be 75 minutes), because the indexing will take some time.

There is one caveat with this approach: it uses Sphinx's index merging feature, which some people have found to have issues. I'm not sure whether it is fine on some versions of Sphinx and not others, so confirming everything works nicely may involve some trial and error. Apparently the 0.9.8.1 version of Sphinx is more reliable than the initial 0.9.8 release.

#### Delayed Deltas

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: This section has not yet been updated with details for Thinking Sphinx v3.</p>
</div>

The more reliable option for smarter delta indexing is using the [Delayed Job](http://github.com/tobi/delayed_job) plugin, which queues up the index requests in a separate process (invoked by a constantly running rake task), instead of dealing with them during each web request. As mentioned earlier on this page, the process will need local disk access to the Sphinx indices (essentially, your DJ workers need to be run on the same machine as Sphinx).

To get this set up in your web application, you'll need to install the separate gem. It has Delayed Job as a dependency, so that will be automatically installed as well.

{% highlight sh %}
gem install ts-delayed-delta
{% endhighlight %}

Don't forget to add the gem's details to your `environment.rb` file:

{% highlight ruby %}
config.gem 'ts-delayed-delta',
  :lib     => 'thinking_sphinx/deltas/delayed_delta',
  :version => '1.1.2'
{% endhighlight %}

Or, for Rails 3 - put the following in your Gemfile:

{% highlight ruby %}
gem 'ts-delayed-delta', '1.1.2',
  :require => 'thinking_sphinx/deltas/delayed_delta'
{% endhighlight %}

And add the following line to the bottom of your `Rakefile`:

{% highlight ruby %}
require 'thinking_sphinx/deltas/delayed_delta/tasks'
{% endhighlight %}

If this is your first time running Delayed Job, then you're going to need the jobs table migration as well:

{% highlight sh %}
script/generate delayed_job
{% endhighlight %}

To enable this approach in your models, change your define_index block to look more like this:

{% highlight ruby %}
define_index do
  # ...

  set_property :delta => :delayed
end
{% endhighlight %}

A boolean column called delta needs to be added to the model as well, just the same as a default delta approach.

{% highlight rb %}
def self.up
  add_column :articles, :delta, :boolean, :default => true,
    :null => false
end
{% endhighlight %}

Once this is all set up, to process the delta indexing jobs, you'll need to run the following rake task - which deliberately doesn't ever stop (as it regularly tackles all jobs lined up):

{% highlight sh %}
rake thinking_sphinx:delayed_delta
rake ts:dd # shortcut
{% endhighlight %}

One very important caveat of the delayed_job method is that it will only work for **a single searchd instance**, which may not the case if you have multiple app servers.  Delayed Job is designed to run each job only once, not once per app server.  Therefore when the delayed_job for the delta index runs, it will only run on the app server that actually processes the job.  The effects of this can range from indistinguishable to subtle depending on the particulars of your setup, so it's important to be aware of this up front. The best approach is to have Sphinx, the database and the delayed job processing task all running on one machine.

Also, keep in mind that because the delta indexing requests are queued, they will not be processed immediately - and so your search results will not not be accurate straight after a change. Delayed Job is pretty fast at getting through the queue though, so it shouldn't take too long.
