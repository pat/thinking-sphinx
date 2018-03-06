---
layout: en
title: Indexing
gem_version: v3
---

## Indexing your Models

* [Basic Indexing](#basic)
* [Real-time Indices vs SQL-backed Indices](#realtime)
* [Fields](#fields)
* [Attributes](#attributes)
* [Conditions and Groupings](#conditions)
* [Sanitizing SQL](#sql)
* [Index Options](#options)
* [Multiple Indices](#multiple)
* [Real-time Callbacks](#callbacks)
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

You'll also want to add [a real-time callback](#callbacks) to your model.

When you're defining indices for namespaced models, use a lowercase string with /'s for namespacing and then casted to a symbol as the model reference:

{% highlight ruby %}
# For a model named Blog::Article:
ThinkingSphinx::Index.define 'blog/article'.to_sym, :with => :active_record
{% endhighlight %}

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>

  <p><strong>Note</strong>: Index definitions for Thinking Sphinx versions before 3.0.0 went in the model files instead, inside a <code>define_index</code> call.</p>

  <p>Don't forget to place this block <em>below</em> your associations and any <code>accepts_nested_attributes_for</code> calls, otherwise any references to them for fields and attributes will not work.</p>

  {% highlight ruby %}
class Article < ActiveRecord::Base
  # ...

  define_index do
    indexes subject, :sortable => true
    indexes content
    indexes author(:name), :as => :author, :sortable => true

    has author_id, created_at, updated_at
  end

  # ...
end
{% endhighlight %}
</div>

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

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>

  <p>Keep in mind that if you're referencing a column that shares its name with a core Ruby method (such as id, name or type) and you're using Thinking Sphinx v1 or v2, then you'll need to specify it using a symbol.</p>

  {% highlight ruby %}
indexes :name
{% endhighlight %}
</div>

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

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>

  <p><strong>Note</strong>: Defining multiple indices in Thinking Sphinx v2 or older is just a matter of using define_index multiple times, and supplying a unique name for each:</p>

  {% highlight ruby %}
define_index 'article_foo' do
  # index definition
end

define_index 'article_bar' do
  # index definition
end
{% endhighlight %}
</div>

<h3 id="callbacks">Real-time Callbacks</h3>

If you're using real-time indices, you will want to add a callback to your model to ensure changes are reflected in Sphinx:

{% highlight ruby %}
# if your model is app/models/article.rb:
after_save ThinkingSphinx::RealTime.callback_for(:article)
{% endhighlight %}

If you want changes to associated data to fire Sphinx updates for a related model, you can specify a method chain for the callback.

{% highlight ruby %}
# in app/models/comment.rb, presuming a comment belongs_to :article
after_save ThinkingSphinx::RealTime.callback_for(
  :article, [:article]
)
{% endhighlight %}

The first argument, in all situations, should match the index definition's first argument: a symbolised version of the model name. The second argument is a chain, and should be in the form of an array of symbols, each symbol representing methods called to get to the indexed object (so, an instance of the Article model in the example above).

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
after_save(
  ThinkingSphinx::RealTime.callback_for(:article) { |instance|
    instance.indexing? ? [instance] : []
  }
)
{% endhighlight %}

You do _not_ need to add a `destroy` callback - Thinking Sphinx does this automatically for all indexed models.

<h3 id="processing">Processing your Index</h3>

Once you've got your index set up just how you like it, you can run [the rake task](rake_tasks.html) to get Sphinx to process the data.

{% highlight sh %}
rake ts:index
{% endhighlight %}

If you have made structural changes to your index (which is anything except adding new data into the database tables), you'll need to stop Sphinx, re-process, and then re-start Sphinx - which can be done through a single rake call.

{% highlight sh %}
rake ts:rebuild
{% endhighlight %}

If you're using real-time indices and a version of Thinking Sphinx prior to v3.4.0, use `ts:generate` and `ts:regenerate` respectively instead (though these will only impact real-time indices, not SQL-backed indices).
