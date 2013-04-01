---
layout: en
title: Searching
---

## Searching

* [Basic Searching](#basic)
* [Field Conditions](#conditions)
* [Attribute Filters](#filters)
* [Application-Wide Search](#global)
* [Pagination](#pagination)
* [Match Modes](#matchmodes)
* [Ranking Modes](#ranking)
* [Sorting](#sorting)
* [Field Weights](#fieldweights)
* [Search Results Information](#results)
* [Grouping/Clustering](#grouping)
* [Searching for Object Ids](#ids)
* [Search Counts](#counts)
* [Avoiding Nil Results](#nils)
* [Automatic Wildcards](#star)
* [Errors](#errors)
* [Advanced Options](#advanced)

<h3 id="basic">Basic Searching</h3>

Once you've [got an index set up](indexing.html) on your model, and have [the Sphinx daemon running](rake_tasks.html), then you can start to search, using a method on your model named just that.

{% highlight ruby %}
Article.search 'pancakes'
{% endhighlight %}

Sphinx does have some reserved characters (including the @ character), so you may need to escape your query terms. Riddle (a dependency of Thinking Sphinx) has escaping methods built-in:

{% highlight ruby %}
# For Thinking Sphinx v3 or newer:
Article.search Riddle::Query.escape(params[:query])
# For Thinking Sphinx before v3:
Article.search Riddle.escape(params[:query])
{% endhighlight %}

Please note that Sphinx paginates search results, and the default page size is 20. You can find more information further down in the [pagination](#pagination) section.

<h3 id="conditions">Field Conditions</h3>

To focus a query on a specific field, you can use the `:conditions` option - much like in ActiveRecord (back before Rails 3, anyway):

{% highlight ruby %}
Article.search :conditions => {:subject => 'pancakes'}
{% endhighlight %}

You can combine both field-specific queries and generic queries too:

{% highlight ruby %}
Article.search 'pancakes', :conditions => {:subject => 'tasty'}
{% endhighlight %}

Please keep in mind that Sphinx does not support SQL comparison operators - it has its own query language. The `:conditions` option must be a hash, with each key a field and each value a string.

<h3 id="filters">Attribute Filters</h3>

Filters on attributes can be defined using a similar syntax, but using the `:with` option.

{% highlight ruby %}
Article.search 'pancakes', :with => {:author_id => @pat.id}
{% endhighlight %}

Filters have the advantage over focusing on specific fields in that they accept arrays and ranges:

{% highlight ruby %}
Article.search 'pancakes', :with => {
  :created_at => 1.week.ago..Time.now,
  :author_id  => @fab_four.collect { |author| author.id }
}
{% endhighlight %}

And of course, you can mix and match global terms, field-specific terms, and filters:

{% highlight ruby %}
Article.search 'pancakes',
  :conditions => {:subject => 'tasty'},
  :with       => {:created_at => 1.week.ago..Time.now}
{% endhighlight %}

If you wish to exclude specific attribute values, then you can specify them using `:without`:

{% highlight ruby %}
Article.search 'pancakes',
  :without => {:user_id => current_user.id}
{% endhighlight %}

For matching multiple values in a multi-value attribute, `:with` doesn't quite do what you want. Give `:with_all` a try instead:

{% highlight ruby %}
Article.search 'pancakes',
  :with_all => {:tag_ids => @tags.collect(&:id)}
{% endhighlight %}

<h3 id="global">Application-Wide Search</h3>

You can use all the same syntax to search across all indexed models in your application:

{% highlight ruby %}
ThinkingSphinx.search 'pancakes'
{% endhighlight %}

If you're using a version of Thinking Sphinx prior to 1.2, you will need to use a slightly deeper namespaced method: `ThinkingSphinx::Search.search`.

This search will return all objects that match, no matter what model they are from, ordered by relevance (unless you specify a custom order clause, of course). Don't expect references to attributes and fields to work perfectly if they don't exist in all the models.

If you want to limit global searches to a few specific models, you can do so with the `:classes` option:

{% highlight ruby %}
ThinkingSphinx.search 'pancakes', :classes => [Article, Comment]
{% endhighlight %}

<h3 id="pagination">Pagination</h3>

Sphinx paginates search results by default. Indeed, there's no way to turn it off (but you can request really big pages should you wish). The parameters for pagination in Thinking Sphinx are exactly the same as [Will Paginate](http://github.com/mislav/will_paginate/tree/master): `:page` and `:per_page`.

{% highlight ruby %}
Article.search 'pancakes', :page => params[:page], :per_page => 42
{% endhighlight %}

The output of search results can be used with Will Paginate's view helper as well, just to keep things nice and easy.

{% highlight ruby %}
# in the controller:
@articles = Article.search 'pancakes'

# in the view:
will_paginate @articles
{% endhighlight %}

<h3 id="matchmodes">Match Modes</h3>

Thinking Sphinx v3 and newer use Sphinx's SphinxQL for querying, and that _always_ uses the extended match mode, which is [covered in detail](http://www.sphinxsearch.com/docs/current.html#extended-syntax) in the Sphinx documentation.

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: If you are using an older version of Thinking Sphinx, then you have simpler match modes available, which are covered both in the Sphinx documentation and <a href="searching/ts2.html#matchmodes">here</a>.</p>
</div>

<h3 id="ranking">Ranking Modes</h3>

Sphinx also has a few different ranking modes (again, [the Sphinx documentation](http://www.sphinxsearch.com/docs/current.html#api-func-setrankingmode) is the best source of information on these). They can be set using the `:ranker` option (or `:rank_mode` if you're using Thinking Sphinx v2 or older):

{% highlight ruby %}
Article.search "pancakes", :ranker => :bm25
{% endhighlight %}

Ranking modes include the following (though the definitive list is in the Sphinx documentation):

#### `:proximity_bm25`

The default ranking mode, which combines both phrase proximity and BM25 ranking (see below).

#### `:bm25`

A statistical ranking mode, similar to most other full-text search engines.

#### `:none`

No ranking - every result has a weight of 1.

#### `:wordcount` (since 0.9.9rc1)

Ranks results purely on the number of times the keywords are found in a document. Field weights are taken into factor.

#### `:proximity` (since 0.9.9rc1)

Ranks documents by raw proximity value.

#### `:match_any` (since 0.9.9rc1)

Returns rankings calculated in the same way as a match mode of `:any`.

#### `:fieldmask` (since 0.9.9rc2)

Returns rankings as a 32-bit mask with the N-th bit corresponding to the N-th field, numbering from 0. The bit will only be set when any of the keywords match the respective field. If you want to know which fields match your search for each document, this is the only way.

<h3 id="sorting">Sorting</h3>

By default, Sphinx sorts by how relevant it believes the documents to be to the given search keywords. However, you can also sort by attributes (and fields flagged as sortable) or custom mathematical expressions.

Sorting expressions are much like SQL's ORDER BY clause - an attribute followed by a direction:

{% highlight ruby %}
Article.search 'pancakes', :order => 'created_at DESC'
{% endhighlight %}

If you supply an attribute as a symbol, it's presumed you want them in ascending order:

{% highlight ruby %}
Article.search "pancakes", :order => :created_at
# is equivalent to
Article.search "pancakes", :order => 'created_at ASC'
{% endhighlight %}

If you want to use a custom expression to define your sorting order, you need to declare that as a dynamic attribute:

{% highlight ruby %}
ThinkingSphinx.search(
  :select => '@weight * 10 + document_boost as custom_weight',
  :order  => 'custom_weight DESC'
)
{% endhighlight %}

And as shown in the above example, Sphinx's calculated ranking is available via the `@weight` keyword (but no longer via its aliases `@relevance` or `@rank`).

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: If you are using an older version of Thinking Sphinx, then you have further sorting options available, which are covered both in the Sphinx documentation and <a href="searching/ts2.html#sorting">here</a>.</p>
</div>

<h3 id="fieldweights">Field Weights</h3>

Sphinx has the ability to weight fields with differing levels of importance. You can set this using the `:field_weights` option in your searches:

{% highlight ruby %}
Article.search "pancakes", :field_weights => {
  :subject => 10,
  :tags    => 6,
  :content => 3
}
{% endhighlight %}

You don't need to specify all fields - any not given values are kept at the default weighting of 1.

If you'd like the same custom weightings to apply to all searches, you can set the values in your index definition:

{% highlight ruby %}
set_property :field_weights => {
  :subject => 10,
  :tags    => 6,
  :content => 3
}
{% endhighlight %}

<h3 id="results">Search Results Information</h3>

If you're building your own pagination output, then you can find out the statistics of your search using the following accessors:

{% highlight ruby %}
@articles = Article.search 'pancakes'
# Number of matches in Sphinx
@articles.total_entries
# Number of pages available
@articles.total_pages
# Current page index
@articles.current_page
# Number of results per page
@articles.per_page
{% endhighlight %}

<h3 id="grouping">Grouping / Clustering</h3>

Sphinx allows you group search records that share a common attribute, which can be useful when you want to show aggregated collections. For example, if you have a set of posts and they are all part of a category and have a category_id, you could group your results by category id and show a set of all the categories matched by your search, as well as all the posts. You can read more about it in the [official Sphinx documentation](http://sphinxsearch.com/docs/current.html#clustering).

For grouping to work, you need to pass in the `:group_by` parameter.

Searching posts, for example:

{% highlight ruby %}
Post.search 'syrup', :group_by => :category_id
{% endhighlight %}

By default, this will return your Post objects, but one per category_id. If you want to sort by how many posts each category contains, you can pass in `:order_group_by`:

{% highlight ruby %}
Post.search 'syrup',
  :group_by       => :category_id,
  :order_group_by => '@count desc'
{% endhighlight %}

Once you have the grouped results, you can enumerate by each result along with the group value, the number of objects that matched that group value, or both, using the following methods respectively:

{% highlight ruby %}
posts.each_with_group           { |post, group| }
posts.each_with_count           { |post, count| }
posts.each_with_group_and_count { |post, group, count| }
{% endhighlight %}

Sphinx's SphinxQL syntax only allows for grouping on a single attribute - but that attribute can be generated in the SELECT part of the query itself:

{% highlight ruby %}
ThinkingSphinx.search(
  :select   => 'MAX(foo, bar) AS grouping',
  :group_by => 'grouping'
)
{% endhighlight %}

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: If you are using an older version of Thinking Sphinx, then you have further grouping options available, which are covered both in the Sphinx documentation and <a href="searching/ts2.html#grouping">here</a>.</p>
</div>

<h3 id="ids">Searching for Object Ids</h3>

If you would like just the primary key values returned, instead of instances of ActiveRecord objects, you can use all the same search options in a call to `search_for_ids` instead.

{% highlight ruby %}
Article.search_for_ids 'pancakes'
ThinkingSphinx.search_for_ids 'pancakes'
{% endhighlight %}

<h3 id="counts">Search Counts</h3>

If you just want the number of matches, instead of the matched objects themselves, then you can use the `search_count` method (which accepts all the same arguments as a normal `search` call). If you're searching globally, then use the `ThinkingSphinx.count` method.

{% highlight ruby %}
Article.search_count 'pancakes'
ThinkingSphinx.count 'pancakes'
{% endhighlight %}

<h3 id="nils">Avoiding Nil Results</h3>

Thinking Sphinx tries its hardest to make sure Sphinx knows when records are deleted, but sometimes stale objects slip through the gaps. To get around this, Thinking Sphinx has the option of retrying searches.

To enable this, you can set `:retry_stale` to true, and Thinking Sphinx will make up to three tries at retrieving a full result set that has no nil values. If you want to change the number of tries, set `:retry_stale` to an integer.

And obviously, this can be quite an expensive call (as it instantiates objects each time), but it provides a better end result in some situations.

{% highlight ruby %}
Article.search 'pancakes', :retry_stale => true
Article.search 'pancakes', :retry_stale => 1
{% endhighlight %}

<h3 id="star">Automatic Wildcards</h3>

If you'd like your search keywords to be wildcards for every search, you can use the `:star` option, which automatically prepends and appends wildcard stars to each word.

{% highlight ruby %}
Article.search 'pancakes waffles', :star => true
# => becomes '*pancakes* *waffles*'
{% endhighlight %}

<h3 id="errors">Errors</h3>

If you construct a query that Sphinx cannot understand, or if the connection fails, an instance of `ThinkingSphinx::SphinxError` will be raised.

Some specific types of errors are given specific subclass - `ThinkingSphinx::QueryError`, `ThinkingSphinx::SyntaxError` and `ThinkingSphinx::ParseError`. The message in any of these errors will give you more detail on what's gone wrong.

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: If you are using an older version of Thinking Sphinx, then <a href="searching/ts2.html#errors">errors are handled differently</a>.</p>
</div>

<h3 id="advanced">Advanced Options</h3>

Thinking Sphinx accepts the following [advanced Sphinx arguments](http://sphinxsearch.com/docs/current.html#sphinxql-select):

* `:cutoff`
* `:retry_count` and `:retry_delay`
* `:max_query_time`
* `:comment`

Thinking Sphinx v1/v2 also allows for the [`:id_range`](http://www.sphinxsearch.com/docs/current.html#api-func-setidrange) option.

If you want to set additional arguments for the underlying SQL call when translating Sphinx results into ActiveRecord objects (`:include`, `:joins`, `:select`, `:order`), you can put these within the `:sql` option:

{% highlight ruby %}
Article.search :sql => {:include => :user}
{% endhighlight %}

And finally - to avoid lazily loading search results and make sure Thinking Sphinx processes the search query immediately, use the `:populate` option:

{% highlight ruby %}
Article.search 'pancakes', :populate => true
# is equivalent to
Article.search('pancakes').populate
{% endhighlight %}

This is particularly useful to ensure exceptions are raised where you expect them to.
