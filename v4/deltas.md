---
layout: en
title: Delta Indexes and Merging
gem_version: v4
redirect_from: "/deltas.html"
---

## Delta Indexes and Merging

If you're using SQL-backed indices (rather than real-time indices) and you wish to keep records up-to-date, you'll come up against a limitation in Sphinx: you can only update records by reprocessing the indices they're stored in.

The common approach around this issue, used by Thinking Sphinx, is the delta index - an index that tracks _just_ the changed documents. Because this index is much smaller, it is super-fast to process.

To set this up in your web application, you need to do **three** things:

1. Add a delta column (with a database index) to your model
2. Turn on delta indexing for the index
3. Stop, re-index and restart Sphinx.

The first item on the list can be done via a migration, perhaps looking something like the following:

{% highlight ruby %}
def self.up
  add_column :articles, :delta, :boolean, :default => true,
    :null => false
  add_index :articles, :delta
end
{% endhighlight %}

Turning on delta indexing is done within your model's define_index block:

{% highlight ruby %}
ThinkingSphinx::Index.define :article, :with => :active_record,
  :delta => true do
  # ...
end
{% endhighlight %}

And finally, we need to rebuild the Sphinx indexes, as we have changed the structure of our Sphinx index setup.

{% highlight sh %}
rake ts:rebuild
{% endhighlight %}

Please note that if you've enabled delta indexing, you will still need to process all indices (via the `ts:index` task) or to [merge](#merging-delta-indices) your delta indices into their corresponding core indices (via the `ts:merge` task) regularly. Either of these approaches ensure the delta changes are kept small and thus fast to process.

It's also worth noting that when each change happens, and the delta indexing is invoked, you will see the output from Sphinx's indexer tool either in your logs, or into your console. This serves as an indication that everything is working, but should you want to hide it, there's a global setting you can use to enable/disable it.

{% highlight yaml %}
production:
  quiet_deltas: true
{% endhighlight %}

<div class="note">
  <p><strong>Note</strong>: Sphinx requires local disk access to your index files to manage delta indices. This means that if you do shift delta processing to some sort of queue (such as Delayed Job, Sidekiq, or Resque), the queue workers will need to run on the same machine as Sphinx.</p>
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
  article.update :delta => true
end
{% endhighlight %}

### Advanced Delta Approaches

One issue with the default delta approach, as outlined above, is that it creates a noticeable speed decrease on busy websites, because the delta indexing is run as part of each request that makes a change to the model records.

#### Background Deltas

The more reliable option for smarter delta indexing is using a background worker such as Delayed Job, Resque or Sidekiq, instead of dealing with them during each web request. As mentioned above, the process will need local disk access to the Sphinx indices (essentially, your worker processes need to be run on the same machine as Sphinx).

To get this set up in your web application, you'll need to set up your background worker gem, and then add the specific Thinking Sphinx integration gem - one of [ts-delayed-delta](https://github.com/pat/ts-delayed-delta), [ts-resque-delta](https://github.com/pat/ts-resque-delta) or [ts-sidekiq-delta](https://github.com/pat/ts-sidekiq-delta).

To enable this approach in your models, you need to refer to the specific delta implementation, which is a class (`ThinkingSphinx::Deltas::DelayedDelta`, `ThinkingSphinx::Deltas::ResqueDelta` or `ThinkingSphinx::Deltas::SidekiqDelta`) for the argument of the `:delta` option:

{% highlight ruby %}
ThinkingSphinx::Index.define(:book,
  :with  => :active_record,
  :delta => ThinkingSphinx::Deltas::SidekiqDelta
) do
  # ...
end
{% endhighlight %}

A boolean column called delta needs to be added to the model as well, just the same as a default delta approach.

{% highlight rb %}
def self.up
  add_column :articles, :delta, :boolean, :default => true,
    :null => false
end
{% endhighlight %}

One very important caveat of this background processing approach is that it will only work for **a single searchd instance**. Delayed Job, Resque and Sidekiq are all designed to run each job only once, not once per app server. The best approach is to have Sphinx and the background job worker processing tasks running on one machine.

Also, keep in mind that because the delta indexing requests are queued, they will not be processed immediately - and so your search results will not not be accurate straight after a change (but, tuned correctly, within a few seconds is likely).

### Merging Delta Indices

Instead of processing _all_ indices regularly to get the core indices containing all the recent changes, you can instead merge the delta into the core directly. This is done using the `ts:merge` rake task:

{% highlight sh %}
rake ts:merge
{% endhighlight %}

The above task will find each delta index that exists and merge it into the core index, and mark all delta flags as false again.

If you only want to merge _some_ delta indices, you can specify which indices via the `INDEX_FILTER` environment variable, which accepts a comma-separated list of index names (minus their `_core`/`_delta` suffix):

{% highlight sh %}
rake ts:merge INDEX_FILTER=article,user
{% endhighlight %}
