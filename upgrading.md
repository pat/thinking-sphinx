---
layout: en
title: Upgrading
---

## Upgrading Thinking Sphinx

Thinking Sphinx has changed quite a bit over time, and if you're upgrading from an old version, you may find some of your code needs to be changed as well. Here's a few tips...

### Upgrading to 3.x from 1.x or 2.x

There's quite a bit that's changed in Thinking Sphinx 3.0, as it's a complete rewrite. First, the important changes:

* [Index definitions](/indexing.html) now live in `app/indices`.
* `config/sphinx.yml` is now `config/thinking_sphinx.yml`.
* `mysql2` gem (at least 0.3.12b4) is required for connecting to Sphinx (using its mysql41 protocol).
* Specifying a different port for Sphinx to use (in `config/thinking_sphinx.yml`) should be done with the mysql41 setting, not the port setting.
* The match mode is always extended - SphinxQL doesn't know any other way.
* If you're explicitly setting a time attribute's type, instead of `:datetime` it should now be `:timestamp`.
* [Sorting options](/searching.html#sorting) and [grouping options](/searching.html#grouping) are much simpler.
* Delta arguments are passed in as an option of the `define` call, not within the block:

{% highlight ruby %}
ThinkingSphinx::Index.define(
  :article, :with => :active_record, :delta => true
) do
  # ...
end
{% endhighlight %}

Other changes for those who have delved a bit further:

* The `searchd_log` and `searchd_query_log` settings are now `log` and `query_log` (matching their Sphinx names).
* You'll need to include `ThinkingSphinx::Scopes` into your models if you want to use Sphinx scopes. Default scopes can be set as follows:

{% highlight ruby %}
class Person < ActiveRecord::Base
  include ThinkingSphinx::Scopes

  sphinx_scope(:date_order) { {:order => :created_at} }
  default_sphinx_scope :date_order
  # ...
end
{% endhighlight %}

* ActiveRecord::Base.set_sphinx_primary_key is now an option in the index definition (alongside the `:with` option): `:primary_key` - and therefore is no longer inheritable between models.
* Suspended deltas are no longer called from the model, but like so instead:

{% highlight ruby %}
ThinkingSphinx::Deltas.suspend :article do
  article.update_attributes(:title => 'pancakes')
end
{% endhighlight %}

* Excerpts through search results behaves the same way, provided you add [an ExcerptsPane](excerpts.html) into the mix.
* When indexing models on classes that are using single-table inheritance (STI), make sure you have a database index on the `type` column. Thinking Sphinx will need to determine which subclasses are available, and we can't rely on Rails having loaded all models at any given point, so it queries the database. If you don't want this to happen, set `:skip_sti` to true in your search call, and ensure that the `:classes` option holds all classes that could be returned.

{% highlight ruby %}
ThinkingSphinx.search 'pancakes',
  :skip_sti => true,
  :classes => [User, AdminUser, SupportUser]
{% endhighlight %}

* The option `:rank_mode` has now become `:ranker` - and the options (as strings or symbols) are as follows: proximity_bm25, bm25, none, wordcount, proximity, matchany, fieldmask, sph04 and expr.
* Support for latitude and longitude attributes named something other than 'lat' and 'lng' or 'latitude' and 'longitude' has been removed. It may be added back in if requested, but not expecting anyone to.
* [ActiveRecord options](/searching.html#advanced) (`:include`, `:joins`, `:select`, `:order`) get passed in via `:sql`.
* `each_with_weight` (note that it's weight, not weighting) is available, but not by default. Here's an example of how to have it part of the search object:

{% highlight ruby %}
search = Article.search('pancakes', :select => '*, @weight')
search.masks << ThinkingSphinx::Masks::WeightEnumeratorMask

search.each_with_weight do |article, weight|
  # ...
end
{% endhighlight %}

* You'll also note here that the internal weight attribute is explicitly included. This is necessary for edge Sphinx post 2.0.5.
* Batched/Bulk searches are done pretty similarly as in the past - here's a code sample that'll only hit Sphinx once:

{% highlight ruby %}
batch = ThinkingSphinx::BatchedSearch.new
batch.searches << Article.search('foo')
batch.searches << Article.search(:conditions => {:name => 'bar'})
batch.searches << Article.search_for_ids('baz')

# When you call batch#populate, the searches are all populated with a single
# Sphinx call.
batch.populate

batch.searches #=> [[foo results], [bar results], [baz results]]
{% endhighlight %}

* To search on specific indices, use the `:indices` option, which expects an array of index names (including the `_core` or `_delta` suffixes).
* `:without_any` has become `:without_all` - and is implemented, but Sphinx doesn't yet support the required logic.
* If you're creating a multi-value attribute manually (using a SQL snippet), then in the definition pass in `:multi => true`, but `:type` should be set as well, to one of the MVA types that Sphinx supports (`:integer`, `:timestamp`, or `:boolean`).
* Automatic updates of non-string attributes are still limited to those from columns on the model in question, and is disabled by default. To enable it, just set attribute_updates to true in your `config/thinking_sphinx.yml`.
* Search result helper methods are no longer injected into the actual result objects. Read the documentation for search results, glazes and panes.
* If you're using string facets, make sure they're defined as fields, not strings. There is currently no support for multi-value string facets.
* To have fine-grained control over when deltas are invoked, create a sub-class of your chosen delta class (the standard is `ThinkingSphinx::Deltas::DefaultDelta`) and customise the `toggle` and `toggled?` methods, both of which accept a single parameter being the ActiveRecord instance.

{% highlight ruby %}
class OccasionalDeltas < ThinkingSphinx::Deltas::DefaultDelta
  # Invoked via a before_save callback. The default behaviour is to set the
  # delta column to true.
  def toggle(instance)
    super unless instance.title_changed?
  end

  # Invoked via an after_commit callback. The default behaviour is to check
  # whether the delta column is set to true. If this method returns true, the
  # indexer is fired.
  def toggled?(instance)
    return false unless instance.title_changed?

    super
  end
end

# And in your index definition:
ThinkingSphinx::Index.define :article, :with => :active_record, :delta => OccasionalDeltas do
  # ...
end
{% endhighlight %}

* Polymorphic associations used within index definitions must be declared with the corresponding models. This is much better than the old approach of querying the database on the *_type column to determine what models to join against.

{% highlight ruby %}
indexes events.eventable.name

polymorphs events.eventable, :to => %w(Page Post User)
{% endhighlight %}

### Upgrading from 2.0.0.rc2 to 2.0.0 or 1.3.20 to 1.4.0

In previous versions of Thinking Sphinx, it was valid to put attribute filters in either `:with` or `:conditions`. For a long while, filters in `:conditions` has been clearly flagged as deprecated, and since 1.4.0 and 2.0.0 it is now removed.

You can still use `:with` for attribute filters and `:conditions` for field-focused queries.

### Upgrading from between 1.3.6 and 1.3.17

If you're using excerpts, for this set of versions they were automatically HTML-escaped. This is now no longer the case, as Sphinx can take care of this automatically for both indexing and excerpts. Just turn on the `html_strip` value in your `sphinx.yml` file:

{% highlight yaml %}
html_strip: true
{% endhighlight %}

### Upgrading from between 1.3.3 and 1.3.7

You no longer have to specify an explicit Sphinx version when requiring Thinking Sphinx - it will figure it out itself. So, you can remove the version require statement from your `Rakefile`, and remove the version suffix in your gem setup in `environment.rb`.

### Upgrading from 1.3.2 or earlier (when using Sphinx 0.9.9)

If you've been using the `sphinx-0.9.9` branch from GitHub or the `thinking-sphinx-099` gem, there is now just one version of Thinking Sphinx that works for both versions (and automatically detects which version you have). The installation page provides a good overview of the new setup.

{% highlight ruby %}
config.gem(
  'thinking-sphinx',
  :lib     => 'thinking_sphinx',
  :version => '1.3.8'
)
{% endhighlight %}

### Upgrading from 1.2.13 or earlier

With the advent of Thinking Sphinx 1.3.0, the [delayed](http://github.com/pat/ts-delayed-delta/) and [datetime](http://github.com/pat/ts-datetime-delta/) delta approaches are now in separate gems. Also, Delayed Job is no longer vendored in Thinking Sphinx, so you may need to install it as a gem or plugin as well.

The delta page has been updated to reflect these changes, so [have a read through that](deltas.html) to figure out how to make sure your application will still work.

If you're not using deltas, or only using the default delta approach, then this change does not affect you.

### Upgrading from 1.1.17 or earlier

In versions of Thinking Sphinx _before_ 1.1.18, the morphology/stemmer defaulted to stem_en (English). Obviously, not every website uses the English language, so this setting has been removed, with no stemmer as the default.

If you would like to keep stem_en as your stemmer, you'll need to add it to your `config/sphinx.yml` file:

{% highlight yaml %}
development:
  morphology: stem_en
test:
  morphology: stem_en
production:
  morphology: stem_en
{% endhighlight %}

To get a better understanding of stemmers, I recommend reading [Sphinx's documentation](http://www.sphinxsearch.com/docs/manual-0.9.8.html#conf-morphology).
