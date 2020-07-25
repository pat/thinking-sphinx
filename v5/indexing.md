---
layout: en
title: Indexing
gem_version: v5
redirect_from: "/indexing.html"
---

## Indexing your Models

* [Basic Indexing](#basic)
* [Callbacks](#callbacks)
* [Index Names](#index-names)
* [Real-time Indices vs SQL-backed Indices](#realtime)
* [Fields](#fields)
* [Attributes](#attributes)
* [Conditions and Groupings](#conditions)
* [Sanitizing SQL](#sql)
* [Index Options](#options)
* [Multiple Indices](#multiple)
* [Processing your Index](#processing)

<h3 id="basic">Basic Indexing</h3>

Everything to set up the indices for your models goes in files in `app/indices`. The files themselves can be named however you like, but I generally opt for `model_name_index.rb`. At the very least, the file name should not be the same as your model's file name. Here's an example of what goes in the file:

{% highlight ruby %}
ThinkingSphinx::Index.define :article, :with => :active_record do
  indexes subject, :sortable => true
  indexes content
  indexes author.name, :as => :author, :sortable => true

  has author_id, created_at, updated_at
end
{% endhighlight %}

You'll notice the first argument is the model name downcased and as a symbol, and we are specifying the processor - `:active_record` - to use SQL-backed indices. Everything inside the block is just like previous versions of Thinking Sphinx, if you're familiar with that (and if not, keep reading).

An equivalent index definition if you want to use **real-time indices** would be:

{% highlight ruby %}
ThinkingSphinx::Index.define :article, :with => :real_time do
  indexes subject, :sortable => true
  indexes content
  indexes author.name, :as => :author, :sortable => true

  has author_id,  :type => :integer
  has created_at, :type => :timestamp
  has updated_at, :type => :timestamp
end
{% endhighlight %}

For both SQL-backed and real-time indices, you'll also want to add [callbacks](#callbacks) to the models that are being indexed.

When you're defining indices for namespaced models, use a lowercase string with /'s for namespacing and then casted to a symbol as the model reference:

{% highlight ruby %}
# For a model named Blog::Article:
ThinkingSphinx::Index.define 'blog/article'.to_sym, :with => :active_record
{% endhighlight %}

<h3 id="callbacks">Callbacks</h3>

To ensure changes are reflected from your database models into Sphinx, you need to explicitly add callbacks to indexed models. This was done automatically in Thinking Sphinx v4 and earlier, but the performance overhead on _all_ model changes was less than ideal, hence now you must specify it for just the indexed models.

{% highlight ruby %}
# if your indexed model is app/models/article.rb:
class Article < ApplicationRecord
  # if you're using SQL-backed indices:
  ThinkingSphinx::Callbacks.append(
    self, :behaviours => [:sql]
  )

  # if you're using SQL-backed indices with deltas:
  ThinkingSphinx::Callbacks.append(
    self, :behaviours => [:sql, :deltas]
  )

  # if you're using real-time indices
  ThinkingSphinx::Callbacks.append(
    self, :behaviours => [:real_time]
  )

  # if you're using namespaced models:
  ThinkingSphinx::Callbacks.append(
    self, 'admin/article', :behaviours => [:real_time]
  )

  # If you have got the `attribute_updates` setting enabled in
  # their config/thinking_sphinx.yml file, you'll want to
  # include the callbacks for that as well:
  ThinkingSphinx::Callbacks.append(
    self, :behaviours => [:sql, :updates]
  )
  # Though given this feature isn't enabled by default, I
  # suspect not many people will need to do this. The setting
  # is only useful for updating attribute values in SQL-backed
  # indices that aren't using deltas. The only way for fields
  # to be updated is by using deltas or real-time indices.
end
{% endhighlight %}

If you want changes to associated data to fire Sphinx updates for a related model and you're using real-time indices, you can specify a method chain for the callback - you'll also want to add the _index reference_ (the first argument in an index definition - usually the model's name as an underscored and lowercase symbol) as the second argument:

{% highlight ruby %}
# in app/models/comment.rb, presuming a comment belongs_to :article
# note the second argument is :article, as per the
# ThinkingSphinx::Index.define call.
ThinkingSphinx::Callbacks.append(
  self, :article, :behaviours => [:real_time], :path => [:article]
)
{% endhighlight %}

The path option is a chain, and should be in the form of an array of symbols, each symbol representing methods called to get to the indexed object (so, an instance of the Article model in the example above).

If you wish to have your callbacks update Sphinx only in certain conditions, you can either define your own callback and then invoke TS if/when needed:

{% highlight ruby %}
after_save :populate_to_sphinx

# ...

def populate_to_sphinx
  return unless indexing?

  ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.new(
    :article
  ).after_save self
end
{% endhighlight %}

Or supply a block to the callback instantiation which returns an array of instances to process:

{% highlight ruby %}
# if your model is app/models/article.rb:
ThinkingSphinx::Callbacks.append(self, :behaviours => [:real_time]) { |instance|
  instance.indexing? ? [instance] : []
}
{% endhighlight %}

If you're combining custom indexing conditions with associated data, then you'll need to supply the reference (as noted above), but the `:path` option is ignored, and instead you'll need to return the appropriate instances instead:

{% highlight ruby %}
# if your model is app/models/comment.rb
# and you want to process related articles:
ThinkingSphinx::Callbacks.append(self, :article, :behaviours => [:real_time]) { |instance|
  # instance is a comment
  instance.saved_changes.keys.include?("content") ? [instance.article] : []
}
{% endhighlight %}

<h3 id="index-names">Index Names</h3>

When translating these index definitions into Sphinx configuration, Thinking Sphinx will use the model's name for the index, and append a `_core` suffix to it. So, an index for `Article` will be named `article_core`.

If you're using SQL-backed indices with deltas, then there is also a corresponding index with the `_delta` suffix - e.g. `article_delta`.

You can set different index names if you wish, using the `:name` option (as noted later in this documentation related to [multiple indices](#multiple) for a single model). However, the suffixes will always be applied.

<h3 id="realtime">Real-time Indices vs SQL-backed Indices</h3>

Thinking Sphinx allows for definitions of both real-time indices and SQL-backed indices. (In previous versions, only SQL-backed indices were available.)

Real-time indices are processed using Sphinx's SphinxQL protocol, and thus are managed by Thinking Sphinx via Ruby, with the following advantages:

* Your fields and attributes reference Ruby methods.
* Real-time records can be updated directly, thus keeping your Sphinx data up-to-date almost immediately. This removes the need for delta indices.

The SQL-backed indices, however, have the potential to be much faster: the indexing process avoids the need to iterate through every record separately, and can use SQL joins to load association data directly.

You'll need to consider which approach will work best for your application, but certainly if your data is changing frequently and you'd like it to be up-to-date, it's worth starting with real-time indices.

The two approaches are distinguished by the `:with` option:

{% highlight ruby %}
# for real-time indices:
ThinkingSphinx::Index.define :article, :with => :real_time do
# ...

# for SQL-backed indices:
ThinkingSphinx::Index.define :article, :with => :active_record do
# ...
{% endhighlight %}

Any differences in behaviour within an index definition are noted in the documentation below.

<h3 id="fields">Fields</h3>

The `indexes` method adds one (or many) fields, by referencing the model's method names (for real-time indices) or column names (for SQL-backed indices). **You cannot reference model methods with SQL-backed indices** - in this case, Sphinx talks directly to your database, and Ruby doesn't get loaded.

{% highlight ruby %}
indexes content
{% endhighlight %}

You don't need to keep the same names as your model, though. Use the `:as` option to signify a new name. Field and attribute names must be unique, so specifying custom names (instead of the column name for both) is essential.

{% highlight ruby %}
indexes content, :as => :post
{% endhighlight %}

You can also flag fields as being sortable.

{% highlight ruby %}
indexes subject, :sortable => true
{% endhighlight %}

Use the `:facet` option to signify a facet.

{% highlight ruby %}
indexes authors.name, :as => :author, :facet => true
{% endhighlight %}

For **real-time indices**, you can drill down on methods that return single objects (such as `belongs_to` associations):

{% highlight ruby %}
indexes author.name, :as => :author
{% endhighlight %}

If you want to collect multiple values into a single field, you will need a method in your model to aggregate this:

{% highlight ruby %}
# in index:
indexes comment_texts

# in model:
def comment_texts
  comments.collect(&:text).join(' ')
end
{% endhighlight %}

With **SQL-backed indices**, if there are associations in your model you can drill down through them to access other columns. Explicit names with the `:as` option are _required_ when doing this.

{% highlight ruby %}
indexes author.name,     :as => :author
indexes author.location, :as => :author_location
{% endhighlight %}

There may be times when a normal column value isn't exactly what you're after, so you can also define your indexes as raw SQL:

{% highlight ruby %}
indexes "LOWER(first_name)", :as => :first_name, :sortable => true
{% endhighlight %}

Again, in this situation, an explicit name is required, and it only works with **SQL-backed indices**.

<h3 id="attributes">Attributes</h3>

The `has` method adds one (or many) attributes, and just like the `indexes` method, it requires references to the model's methods (for **real-time indices**) or column names (for **SQL-backed indices**).

Real-time indices require the attribute types to be set manually, but SQL-backed indices have the ability to introspect on the database to determine types. Known types for real-time indices are: `integer`, `boolean`, `string`, `timestamp`, `float`, `bigint` and `json`.

{% highlight ruby %}
# In a real-time index:
has author_id, :type => :integer

# In a SQL-backed index:
has author_id
{% endhighlight %}

The syntax is very similar to setting up fields. You can set custom names, and drill down into associations. You don't ever need to label an attribute as `:sortable` though - in Sphinx, all attributes can be used for sorting.

You'll also see below that multi-value attributes in **real-time indices** need the `:multi` option to be set.

Please note that Sphinx only supports [multi-value attributes](http://sphinxsearch.com/docs/current.html#conf-sql-attr-multi) for 32-bit and 64-bit integers and timestamps. This applies to both SQL-backed and real-time indices. [Strings are sadly not supported](common_issues.html#mva-strings).

{% highlight ruby %}
# In a real-time index:
has id, :as => :article_id, :type => :integer
has tag_ids, :multi => true

# In a SQL-backed index:
has id, :as => :article_id
has tag_ids, :as => :tag_ids
{% endhighlight %}

Again: fields and attributes cannot share names - they must all be unique. Use the `:as` option to provide custom names when a column is being used more than once.

<h3 id="conditions">Conditions and Groupings</h3>

Because **SQL-backed indices** are translated to SQL, you may want to add some custom conditions or groupings manually - and for that, you'll want the `where` and `group_by` methods:

{% highlight ruby %}
where "status = 'active'"

group_by "user_id"
{% endhighlight %}

For **real-time indices** you can define a custom scope to preload associations or apply custom conditions:

{% highlight ruby %}
scope { Article.includes(:comments) }
{% endhighlight %}

This scope only comes into play when populating all records at once, not when single records are created or updated.

<h3 id="sql">Sanitizing SQL</h3>

**Note**: this section applies only to SQL-backed indices.

As previously mentioned, your index definition results in SQL from the indexes, the attributes, conditions and groupings, etc. With this in mind, it may be useful to simplify your index.

One way would be to use something like `ActiveRecord::Base.sanitize_sql` to generate the required SQL for you. For example:

{% highlight ruby %}
where sanitize_sql(["published", true])
{% endhighlight %}

This will produce the expected `WHERE published = 1` for MySQL.

<h3 id="options">Index Options</h3>

Most [Sphinx index configuration](http://sphinxsearch.com/docs/current.html#confgroup-index) options can be set on a per-index basis using the `set_property` method within your index definition. Here's an example for the `min_infix_len` option:

{% highlight ruby %}
ThinkingSphinx::Index.define :article, :with => :active_record do
  # ...

  set_property :min_infix_len => 3
end
{% endhighlight %}

`set_property` takes a hash of options, but also can be called as many times as you'd like.

<h3 id="multiple">Multiple Indices</h3>

If you want more than one index defined for a given model, just add further `ThinkingSphinx::Index.define` calls - but make sure you give every index a unique name, and have the same attributes defined in all indices.

{% highlight ruby %}
ThinkingSphinx::Index.define(
  :article, :name => 'article_foo', :with => :active_record
) do
  # index definition
end

ThinkingSphinx::Index.define(
  :article, :name => 'article_bar', :with => :active_record
) do
  # index definition
end
{% endhighlight %}

These index definitions can be in the same file or separate files - it's up to you.

<h3 id="processing">Processing your Index</h3>

Once you've got your index set up just how you like it, you can run [the rake task](rake_tasks.html) to get Sphinx to process the data.

{% highlight sh %}
rake ts:index
{% endhighlight %}

If you have made structural changes to your index (which is anything except adding new data into the database tables), you'll need to stop Sphinx, re-process, and then re-start Sphinx - which can be done through a single rake call.

{% highlight sh %}
rake ts:rebuild
{% endhighlight %}

#### Index Guard Files

Any given SQL-backed index can not be processed more than once concurrently. To avoid multiple indexing requests, Thinking Sphinx adds a lock file in the indices directory while indexing occurs, named `ts-INDEXNAME.tmp`. When you're processing all indices in the one call (via either of the above rake tasks), then the lock file is instead named `ts--all.tmp`.

In rare cases (generally when the parent process crashes completely), orphan lock files may remain - these are safe to remove if no indexing is occured. If you're finding some of your indices aren't being processed reliably, checking for these index files is recommended.

These lock files are not created when processing real-time indices.

You can disable the use of these lock files if you wish, by changing the guarding strategy:

{% highlight ruby %}
# This can go in an initialiser:
ThinkingSphinx::Configuration.instance.guarding_strategy =
  ThinkingSphinx::Guard::None
{% endhighlight %}

#### Processing Approaches

By default, `ts:index` will instruct Sphinx to process all indices (and this has always been how Thinking Sphinx has behaved). This means that Sphinx will prepare all of the new data together before switching the daemon over to use it.

It is possible, though, to instead process each index one at a time (and thus, the daemon uses each index's new data as that index's processing is completed):

{% highlight ruby %}
# This can go in an initialiser:
ThinkingSphinx::Configuration.instance.indexing_strategy =
  ThinkingSphinx::IndexingStrategies::OneAtATime
{% endhighlight %}

Should you wish to build your own indexint strategy, you can give `ThinkingSphinx::Configuration.instance.indexing_strategy` anything you like that responds to call and expects an array of index options, and yields index names. You can see the implementations of the two approaches [here](https://github.com/pat/thinking-sphinx/tree/develop/lib/thinking_sphinx/indexing_strategies).

You can also process just specific indices via the `INDEX_FILTER` environment variable:

{% highlight sh %}
rake ts:index INDEX_FILTER=article_core,user_delta
{% endhighlight %}
