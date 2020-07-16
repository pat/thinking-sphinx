---
layout: en
title: Common Questions and Issues
gem_version: v5
redirect_from: "/common_issues.html"
---

## Common Questions and Issues

Depending on how you have Sphinx setup, or what database you're using, you might come across little issues and curiosities. Here's a few to be aware of.

* [Editing the generated Sphinx configuration file](#editconf)
* [Running multiple instances of Sphinx on one machine](#multiple)
* [Viewing Result Weights](#weights)
* [Wildcard Searching](#wildcards)
* [Slow Indexing](#slow_indexing)
* [MySQL and Large Fields](#mysql_large_fields)
* [PostgreSQL with Manual Fields and Attributes](#postgresql)
* [Delta Indexing Not Working](#deltas)
* [Running Delta Indexing with Passenger](#passenger)
* [Can only access the first thousand search results](#thousand_limit)
* [Filtering on String Attributes](#string_filters)
* [Removing HTML from Excerpts](#escape_html)
* [Using other Database Adapters](#other_adapters)
* [Using OR Logic with Attribute Filters](#or_attributes)
* [Catching Exceptions when Searching](#exceptions)
* [Using with Unicorn](#unicorn)
* [Alternatives to MVAs with Strings](#mva-strings)
* [Indices not being processed](#ignored-indices)

<h3 id="editconf">Editing the generated Sphinx configuration file</h3>

In most situations, you won't need to edit this file yourself, and can rely on Thinking Sphinx to generate it reliably.

If you do want to customise the settings, you'll find most options are available to set via `config/thinking_sphinx.yml` - many are mentioned on the [Advanced Sphinx Configuration page](advanced_config.html). For those that aren't mentioned on that page, you could still try setting it, and there's a fair chance it will work.

On the off chance that you actually do need to edit the file, make sure you're running the `ts:index` task with the `INDEX_ONLY` environment variable set to true, otherwise the task will always regenerate the configuration file, overwriting your customisations.

<h3 id="multiple">Running multiple instances of Sphinx on one machine</h3>

You can run as many Sphinx instances as you wish on one machine - but each must be bound to a different port. You can do this via the `config/thinking_sphinx.yml` file - just add a setting for the port for the specific environment using the mysql41 setting:

{% highlight yaml %}
staging:
  mysql41: 9313
{% endhighlight %}

Other options are documented on the [Advanced Sphinx Configuration page](advanced_config.html).

<h3 id="weights">Viewing Result Weights</h3>

To retrieve the weights/rankings of each search result, you can enumerate through your matches using `each_with_weight`, once you've added the appropriate mask:

{% highlight ruby %}
search = Article.search('pancakes', :select => '*, weight()')
search.masks << ThinkingSphinx::Masks::WeightEnumeratorMask

search.each_with_weight do |article, weight|
  # ...
end
{% endhighlight %}

If you want to access weights directly for each search result, you should add a weight pane to the search context:

{% highlight ruby %}
search = Article.search('pancakes', :select => '*, weight()')
search.context[:panes] << ThinkingSphinx::Panes::WeightPane

search.each do |article|
  article.weight
end
{% endhighlight %}

<h3 id="wildcards">Wildcard Searching</h3>

Sphinx can support wildcard searching (for example: Austr&lowast;), though it is turned off by default in Sphinx 2.1. To enable it, you need to add two settings to your `config/thinking_sphinx.yml` file:

{% highlight yaml %}
development:
  enable_star: 1
  min_infix_len: 1
test:
  enable_star: 1
  min_infix_len: 1
production:
  enable_star: 1
  min_infix_len: 1
{% endhighlight %}

You can set the `min_infix_len` value to something higher if you don't need single characters with a wildcard being matched. This may be a worthwhile fine-tuning, because the smaller the infixes are, the larger your index files become.

Don't forget to rebuild your Sphinx indexes after making this change.

{% highlight sh %}
rake ts:rebuild
{% endhighlight %}

<h3 id="slow_indexing">Slow Indexing</h3>

If Sphinx is taking a while to process all your records, there are a few common reasons for this happening. Firstly, make sure you have database indexes on any foreign key columns and any columns you filter or sort by.

Secondly - are you using fixtures, or are there large gaps between primary key values for your models? Sphinx isn't set up to process disparate IDs efficiently by default - and Rails' fixtures have randomly generated IDs, which are usually extremely large integers. To get around this, you'll need to set `sql_range_step` in your `config/thinking_sphinx.yml` file for the appropriate environments:

{% highlight yaml %}
development:
  sql_range_step: 10000000
{% endhighlight %}

<h3 id="mysql_large_fields">MySQL and Large Fields</h3>

If you've got a field that is built off multiple values in one column from a MySQL database - ie: through a has_many association - then you may hit MySQL's default limit for string concatenation: 1024 characters. You can increase the [group_concat_max_len](http://dev.mysql.com/doc/refman/5.1/en/server-system-variables.html#sysvar_group_concat_max_len) value by adding the following to your index definition:

{% highlight rb %}
set_property :group_concat_max_len => 8192
{% endhighlight %}

If these fields get particularly large though, then there's another setting you may need to set in your MySQL configuration: [max_allowed_packet](http://dev.mysql.com/doc/refman/5.1/en/server-system-variables.html#sysvar_max_allowed_packet), which has a default of sixteen megabytes. You can't set this option via Thinking Sphinx though (it's a rare edge case).

<h3 id="postgresql">PostgreSQL with Manual Fields and Attributes</h3>

If you're using fields or attributes defined by strings (raw SQL) in SQL-backed indices, then the columns used in them aren't automatically included in the GROUP BY clause of the generated SQL statement. To make sure the query is valid, you will need to explicitly add these columns to the GROUP BY clause.

A common example is if you're converting latitude and longitude columns from degrees to radians via SQL.

{% highlight ruby %}
has "RADIANS(latitude)",  :as => :latitude,  :type => :float
has "RADIANS(longitude)", :as => :longitude, :type => :float

group_by "latitude", "longitude"
{% endhighlight %}

<h3 id="deltas">Delta Indexing Not Working</h3>

Often people find delta indexing isn't working on their production server. Sometimes, this is because Sphinx is running as one user on the system, and the Rails application is being served as a different user. Check your production.log and Apache/Nginx error log file for mentions of permissions issues to confirm this.

Indexing for deltas is invoked by the web user, and so needs to have access to the index files. The simplest way to ensure this is by running all Thinking Sphinx rake tasks with that web user.

If you're still having issues, and you're using Passenger, read the next hint.

<h3 id="passenger">Running Delta Indexing with Passenger</h3>

If you're using Phusion Passenger on your production server, with delta indexing on some models, a common issue people find is that their delta indexes don't get processed.

If it's not a permissions issue (see the previous hint), another common cause is because Passenger has its own PATH set up, and can't execute the Sphinx binaries (indexer and searchd) implicitly.

The way around this is to find out where your binaries are on the server:

{% highlight sh %}
which searchd
{% endhighlight %}

And then set the bin_path option in your `config/thinking_sphinx.yml` file for the production environment:

{% highlight yaml %}
production:
  bin_path: '/usr/local/bin'
{% endhighlight %}

<h3 id="thousand_limit">Can only access the first thousand search results</h3>

This is actually how Sphinx is supposed to behave. Have a read of the [Large Result Sets section of the Advanced Configuration page](advanced_config.html#large-result-sets) to see why, and how to work around it if you really need to.

<h3 id="string_filters">Filtering on String Attributes</h3>

To filter by string attributes, you must be using Sphinx 2.2.3 or newer. If that's not possible, the workarounds covered in [older documentation](../v3/common_issues.html#string_filters) could be viable.

<h3 id="escape_html">Removing HTML from Excerpts</h3>

For a while, Thinking Sphinx auto-escaped excerpts. However, Sphinx itself can remove HTML entities for indexing and excerpts, which is a better way to approach this. So, you'll want to add the following setting to your `config/thinking_sphinx.yml` file:

{% highlight yaml %}
html_strip: true
{% endhighlight %}

<h3 id="other_adapters">Using other Database Adapters</h3>

If you're using Thinking Sphinx in combination with a database adapter that isn't quite run-of-the-mill, you may need to add a snippet of code to a Rails initialiser or equivalent.

{% highlight ruby %}
# Set the behaviour to use MySQL syntax and functions.
ThinkingSphinx::ActiveRecord::DatabaseAdapters.default =
  ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter
{% endhighlight %}

<h3 id="or_attributes">Using OR Logic with Attribute Filters</h3>

It is possible to filter on attributes using OR logic. There are two steps: firstly, you need to create a computed attribute while searching, using Sphinx's select option, and _then_ filter by that computed value.

Here's an example where we want to return all publicly visible articles, as well as articles belonging to the user with an ID of 5.

{% highlight ruby %}
with_display = "*, IF(visible = 1 OR user_id = 5, 1, 0) AS display"
Article.search 'pancakes',
  :select => with_display,
  :with  => {'display' => 1}
{% endhighlight %}

If you've given your attributes aliases (using the `:as` option) in your index definition, then you must refer to those attributes by their aliases, not the original database columns. This applies generally to anything using those attributes (filtering, ordering, facets, etc).

For further reading, I recommend Sphinx's documentation on both [the select option](http://sphinxsearch.com/docs/manual-0.9.9.html#api-func-setselect) and [expression syntax](http://sphinxsearch.com/docs/manual-0.9.9.html#sort-expr).

<h3 id="exceptions">Catching Exceptions when Searching</h3>

By default, Thinking Sphinx does not execute the search query until you examine your search results - which is usually in the view. This is so you can chain sphinx scopes without sending multiple (unnecessary) queries to Sphinx.

However, this means that exceptions will be fired from within the view - and most people put their exception handling in the controller. To force exceptions to fire when you actually define the search, all you need to do is to inform Thinking Sphinx that it should populate the results immediately:

{% highlight ruby %}
Article.search 'pancakes', :populate => true
{% endhighlight %}

If you're chaining scopes together, make sure you add this at the end with a final search call:

{% highlight ruby %}
Article.published.search :populate => true
{% endhighlight %}

<h3 id="unicorn">Using with Unicorn</h3>

If you're using Unicorn as your web server, you'll want to ensure the connection pool is cleared after forking.

{% highlight ruby %}
after_fork do |server, worker|
  # Add this to an existing after_fork block if needed.
  ThinkingSphinx::Connection.pool.clear
end
{% endhighlight %}

<h3 id="mva-strings">Alternatives to MVAs with Strings</h3>

Given Sphinx doesn't support multi-value _string_ attributes, what are alternative ways to achieve similar functionality?

The easiest approach is when the string values are coming from an association. In this case, use the foreign key ids instead, and translate string values to the underlying id when you're filtering your searches.

Otherwise, you could look into using [CRC'd integer values of strings](../v3/common_issues.html#string_filters), though there is the possibility of collisions.

<h3 id="ignored-indices">Indices not being processed</h3>

If you're finding indices aren't being processed - particularly delta indices - it could be that [guard files](rake_tasks.html#index-guard-files) haven't been cleaned up properly. They are located in the indices directory, and take the name pattern `ts-INDEXNAME.tmp`.

Provided there is no indexing occuring, they can safely be deleted.
