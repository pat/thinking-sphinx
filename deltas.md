---
layout: en
title: Delta Indexes
---

## Delta Indexes

Sphinx has one major limitation when compared to a lot of other search services: you cannot update the fields a single document in a SQL-backed index, but have to re-process all the data for that index (this limitation, however, does not exist for [real-time indices](http://freelancing-gods.com/posts/rewriting_thinking_sphinx_introducing_realtime_indices)).

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

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: For older versions of Thinking Sphinx, deltas are enabled by adding <code>set_property :delta => true</code> within the <code>define_index</code> block.</p>
</div>

And finally, we need to rebuild the Sphinx indexes, as we have changed the structure of our Sphinx index setup.

{% highlight sh %}
rake ts:rebuild
{% endhighlight %}

Turning on delta indexing does not remove the need for regularly running a full re-index, as otherwise the delta index itself will grow to become just as large as the core indexes, and this removes the advantage of keeping it separate. It also slows down your requests to your server that make changes to the model records.

It's also worth noting that when each change happens, and the delta indexing is invoked, you will see the output from Sphinx's indexer tool either in your logs, or into your console. This serves as an indication that everything is working, but should you want to hide it, there's a global setting you can use to enable/disable it.

In Thinking Sphinx v3, you want to add a setting to the appropriate environments in `config/thinking_sphinx.yml`:

{% highlight yaml %}
production:
  quiet_deltas: true
{% endhighlight %}

In Thinking Sphinx v1/v2, it belongs in an initializer:

{% highlight rb %}
ThinkingSphinx.suppress_delta_output = true
{% endhighlight %}

<div class="note">
  <p><strong>Note</strong>: Sphinx requires local disk access to your index files to manage delta indices. This means that if you do shift delta processing to some sort of queue (such as Delayed Job, discussed below, or Resque), the queue workers will need to run on the same machine as Sphinx.</p>
</div>

### Deltas and Associations

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

#### Delayed Deltas

The more reliable option for smarter delta indexing is using a background worker such as Delayed Job, Resque or Sidekiq, instead of dealing with them during each web request. As mentioned earlier on this page, the process will need local disk access to the Sphinx indices (essentially, your worker processes need to be run on the same machine as Sphinx).

To get this set up in your web application, you'll need to set up your background worker gem, and then add the specific Thinking Sphinx integration gem - one of ts-delayed-delta, ts-resque-delta or ts-sidekiq-delta. The Delayed Job and Resque implementations work with TS v1, v2 and v3, but the Sidekiq implementation is only compatible with TS v3.

To enable this approach in your models, you need to refer to the specific delta implementation, which is a class (`ThinkingSphinx::Deltas::DelayedDelta`, `ThinkingSphinx::Deltas::ResqueDelta` or `ThinkingSphinx::Deltas::SidekiqDelta`) for the argument of the `:delta` option:

{% highlight ruby %}
# In Thinking Sphinx v3:
ThinkingSphinx::Index.define(:book,
  :with  => :active_record,
  :delta => ThinkingSphinx::Deltas::DelayedDelta
) do
  # ...
end

# In Thinking Sphinx v1/v2:
define_index do
  # ...

  set_property :delta => ThinkingSphinx::Deltas::DelayedDelta
end
{% endhighlight %}

A boolean column called delta needs to be added to the model as well, just the same as a default delta approach.

{% highlight rb %}
def self.up
  add_column :articles, :delta, :boolean, :default => true,
    :null => false
end
{% endhighlight %}

One very important caveat of this background processing approach is that it will only work for **a single searchd instance**, which may not the case if you have multiple app servers.  Delayed Job, Resque and Sidekiq are all designed to run each job only once, not once per app server.  Therefore when the job for the delta index runs, it will only run on the app server that actually processes the job.  The effects of this can range from indistinguishable to subtle depending on the particulars of your setup, so it's important to be aware of this up front. The best approach is to have Sphinx, the database and the delayed job processing task all running on one machine.

Also, keep in mind that because the delta indexing requests are queued, they will not be processed immediately - and so your search results will not not be accurate straight after a change (but, tuned correctly, within a few seconds is likely).


#### Timestamp/Datetime Deltas

This approach is managed by using a timestamp column to track when changes have happened, and then run a rake task to index just those changes on a regular basis.

This functionality is in a separate gem `ts-datetime-delta`, so you'll need to install it/add it to your Gemfile. Then, make sure the rake tasks are available, by adding the following line to the end of your `Rakefile`:

{% highlight ruby %}
require 'thinking_sphinx/deltas/datetime_delta/tasks'
{% endhighlight %}

As for your models, no delta column is required for this method, and enabling it is done by the following code in the define_index block:

% highlight ruby %}
# In Thinking Sphinx v3:
ThinkingSphinx::Index.define(:book,
  :with          => :active_record,
  :delta         => ThinkingSphinx::Deltas::DatetimeDelta,
  :delta_options => {:threshold => 1.hour}
) do
  # ...
end

# In Thinking Sphinx v1/v2:
define_index do
  # ...

  set_property :delta => ThinkingSphinx::Deltas::DelayedDelta,
    :threshold => 1.hour
end
{% endhighlight %}

This will use the `updated_at` column - if you wish to use a different column, specify it using the `:delta_column` option. The threshold value is important to note: this is how often you'll need to process the delta indexes via a rake task:

{% highlight sh %}
rake thinking_sphinx:index:delta
rake ts:in:delta # shortcut
{% endhighlight %}

It's actually best to set the threshold a bit higher than the occurance of the rake task (so in this example, maybe the threshold should be 75 minutes), because the indexing will take some time.

There is one caveat with this approach: it uses Sphinx's index merging feature, which some people have found to have issues. I'm not sure whether it is fine on some versions of Sphinx and not others, so confirming everything works nicely may involve some trial and error. (From what I understand, reliability has improved since Sphinx v0.9.)
