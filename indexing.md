---
layout: en
title: Indexing
---

## Indexing your Models

* [Basic Indexing](#basic)
* [Fields](#fields)
* [Attributes](#attributes)
* [Conditions and Groupings](#conditions)
* [Sanitizing SQL](#sql)
* [Multiple Indices](#multiple)
* [Processing your Index](#processing)

<h3 id="basic">Basic Indexing</h3>

Everything to set up the indices for your models goes in files in `app/indices`. The files themselves can be named however you like, but I generally opt for `model_name_index.rb`. Here's an example of what goes in the file:

{% highlight ruby %}
ThinkingSphinx::Index.define :article, :with => :active_record do
  indexes subject, :sortable => true
  indexes content
  indexes author(:name), :as => :author, :sortable => true

  has author_id, created_at, updated_at
end
{% endhighlight %}

You'll notice the first argument is the model name downcased and as a symbol, and we are specifying the processor - `:active_record`. Everything inside the block is just like previous versions of Thinking Sphinx, if you're familiar with that.

When you're defining indices for namespaced models, use a lowercase string with /'s for namespacing as the model reference:

{% highlight ruby %}
# For a model named Blog::Article:
ThinkingSphinx::Index.define 'blog/article', :with => :active_record
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

<h3 id="fields">Fields</h3>

The `indexes` method adds one (or many) fields, by referencing the model's column names. **You cannot reference model methods** - Sphinx talks directly to your database, and Ruby doesn't get loaded at this point.

{% highlight ruby %}
indexes content
{% endhighlight %}

Keep in mind that if you're referencing a column that shares its name with a core Ruby method (such as id, name or type), then you'll need to specify it using a symbol.

{% highlight ruby %}
indexes :name
{% endhighlight %}

You don't need to keep the same names as the database, though. Use the `:as` option to signify an alias.

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

If there are associations in your model, you can drill down through them to access other columns. Explicit aliases are _required_ when doing this.

{% highlight ruby %}
indexes author(:name), :as => :author
indexes author.location, :as => :author_location
{% endhighlight %}

There may be times when a normal column value isn't exactly what you're after, so you can also define your indexes as raw SQL:

{% highlight ruby %}
indexes "LOWER(first_name)", :as => :first_name, :sortable => true
{% endhighlight %}

Again, in this situation, an explicit alias is required.

<h3 id="attributes">Attributes</h3>

The `has` method adds one (or many) attributes, and just like the `indexes` method, it requires references to the model's column names.

{% highlight ruby %}
has author_id
{% endhighlight %}

The syntax is very similar to setting up fields. You can set aliases, and drill down into associations. You don't ever need to label an attribute as `:sortable` though - in Sphinx, all attributes can be used for sorting.

Also, just like fields, if you're referring to a reserved method of Ruby (such as id, name or type), you need to use a symbol (which, when dealing with associations, is within a method call).

{% highlight ruby %}
has :id, :as => :article_id
has tags(:id), :as => :tag_ids
{% endhighlight %}

<h3 id="conditions">Conditions and Groupings</h3>

Because the index is translated to SQL, you may want to add some custom conditions or groupings manually - and for that, you'll want the `where` and `group_by` methods:

{% highlight ruby %}
where "status = 'active'"

group_by "user_id"
{% endhighlight %}

<h3 id="sql">Sanitizing SQL</h3>

As previously mentioned, your index definition results in SQL from the indexes, the attributes, conditions and groupings, etc. With this in mind, it may be useful to simplify your index.

One way would be to use something like `ActiveRecord::Base.sanitize_sql` to generate the required SQL for you. For example:

{% highlight ruby %}
where sanitize_sql(["published", true])
{% endhighlight %}

This will produce the expected `WHERE published = 1` for MySQL.

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

<h3 id="processing">Processing your Index</h3>

Once you've got your index set up just how you like it, you can run [the rake task](rake_tasks.html) to get Sphinx to process the data.

{% highlight sh %}
rake ts:index
{% endhighlight %}

However, if you have made structural changes to your index (which is anything except adding new data into the database tables), you'll need to stop Sphinx, re-index, and then re-start Sphinx - which can be done through a single rake call.

{% highlight sh %}
rake ts:rebuild
{% endhighlight %}
