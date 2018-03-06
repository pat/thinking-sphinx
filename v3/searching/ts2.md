---
layout: en
title: Searching
gem_version: v3
disable_versions: true
---

## Searching with Thinking Sphinx v1/v2

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>

  <p><strong>Note</strong>: These sections only apply to Thinking Sphinx v1/v2. The <a href="/thinking-sphinx/searching.html">main searching documentation</a> is where to find instructions for v3 releases.
</div>

* [Match Modes](#matchmodes)
* [Sorting](#sorting)
* [Grouping/Clustering](#grouping)
* [Errors](#errors)

<h3 id="matchmodes">Match Modes</h3>

Sphinx has several different ways of matching the given search keywords, which can be set on a per-query basis using the `:match_mode` option.

{% highlight ruby %}
Article.search 'pancakes waffles', :match_mode => :any
{% endhighlight %}

Most are pretty self-explanatory, but here's a quick guide. If you need more detail, check out [Sphinx's own documentation](http://www.sphinxsearch.com/docs/current.html#matching-modes).

#### `:all`

This is the default for Thinking Sphinx, and requires a document to have every given word somewhere in its fields.

#### `:any`

This will return documents that include at least one of the keywords in their fields.

#### `:phrase`

This matches all given words together in one place, in the same order. It's just the same as wrapping a Google search in quotes.

#### `:boolean`

This allows you to use boolean logic with your keywords. &amp; is AND, | is OR, and both - and ! function as NOTs. You can group logic within parentheses.

{% highlight ruby %}
Article.search 'pancakes &amp; waffles', :match_mode => :boolean
Article.search 'pancakes | waffles', :match_mode => :boolean
Article.search 'pancakes !waffles',  :match_mode => :boolean
Article.search '( pancakes topping ) | waffles',
  :match_mode => :boolean
{% endhighlight %}

Keep in mind that ANDs are used implicitly if no logic is given, and you can't query with just a NOT - Sphinx needs at least one keyword to match.

#### `:extended`

Extended combines boolean searching with phrase searching, [field-specific searching](/thinking-sphinx/searching.html#conditions), field position limits, proximity searching, quorum matching, strict order operator, exact form modifiers (since 0.9.9rc1) and field-start and field-end modifiers (since 0.9.9rc2).

I highly recommend having a look at [Sphinx's syntax examples](http://www.sphinxsearch.com/docs/current.html#extended-syntax). Also keep in mind that if you use the `:conditions` option, then this match mode will be used automatically.

#### `:extended2`

This is much like the normal extended mode, but with some quirks that Sphinx's documentation doesn't cover. Generally, if you don't know you want to use it, don't worry about using it.

#### `:fullscan`

This match mode ignores all keywords, and just pays attention to filters, sorting and grouping.

<h3 id="sorting">Sorting</h3>

By default, Sphinx sorts by how relevant it believes the documents to be to the given search keywords. However, you can also sort by attributes (and fields flagged as sortable), as well as time segments or custom mathematical expressions.

Attribute sorting defaults to ascending order:

{% highlight ruby %}
Article.search "pancakes", :order => :created_at
{% endhighlight %}

If you want to switch the direction to descending, use the `:sort_mode` option:

{% highlight ruby %}
Article.search "pancakes", :order => :created_at,
  :sort_mode => :desc
{% endhighlight %}

If you want to use multiple attributes, or Sphinx's ranking scores, then you'll need to use the `:extended` sort mode. This will be set by default if you pass in a string to `:order`, but you can set it manually if you wish. This syntax is pretty much the same as SQL, and directions (ASC and DESC) are required for each attribute.

{% highlight ruby %}
Article.search "pancakes", :sort_mode => :extended,
  :order => "created_at DESC, @relevance DESC"
{% endhighlight %}

As well as using any attributes and sortable fields here, you can also use Sphinx's internal attributes (prefixed with @). These are:

* @id (The match's document id)
* @weight, @rank or @relevance (The match's ranking weight)
* @random (Returns results in random order)

#### Expression Sorting

If you're hoping to make your ranking algorithm a bit more complex, then you can break out the arithmetic and use Sphinx's expression sort mode:

{% highlight ruby %}
Article.search "pancakes", :sort_mode => :expr,
  :order => "@weight * views * karma"
{% endhighlight %}

[Reading the Sphinx documentation](http://www.sphinxsearch.com/docs/current.html#sorting-modes) is required if you really want to understand the power and options around this sorting method.

#### Time Segment Sorting

Sphinx also has a curious sort mode, `:time_segments`. This breaks down a given timestamp/datetime attribute into the following segments, and then the matches within the segments are sorted by their ranking.

* Last Hour
* Last Day
* Last Week
* Last Month
* Last 3 Months
* Everything else

You can't change the segment points - these are fixed by Sphinx. To use this sort method, you need to specify it as well as the attribute to use as a reference point:

{% highlight ruby %}
Article.search "pancakes", :sort_mode => :time_segments,
  :sort_by => :updated_at
{% endhighlight %}

<h3 id="grouping">Grouping / Clustering</h3>

Sphinx allows you group search records that share a common attribute, which can be useful when you want to show aggregated collections. For example, if you have a set of posts and they are all part of a category and have a category_id, you could group your results by category id and show a set of all the categories matched by your search, as well as all the posts. You can read more about it in the [official Sphinx documentation](http://sphinxsearch.com/docs/current.html#clustering).

For grouping to work, you need to pass in the `:group_by` parameter and a `:group_function` parameter.

Searching posts, for example:

{% highlight ruby %}
Post.search 'syrup',
  :group_by       => 'category_id',
  :group_function => :attr
{% endhighlight %}

By default, this will return your Post objects, but one per category_id. If you want to sort by how many posts each category contains, you can pass in `:group_clause`:

{% highlight ruby %}
Post.search 'syrup',
  :group_by       => 'category_id',
  :group_function => :attr,
  :group_clause   => "@count desc"
{% endhighlight %}

You can also group results by date. Given you have a date column in your index:

{% highlight ruby %}
class Post < ActiveRecord::Base
  define_index
    ...
    has :created_at
  end
end
{% endhighlight %}

Then you can group search results by that date field:

{% highlight ruby %}
Post.search 'treacle',
  :group_by       => 'created_at',
  :group_function => :day
{% endhighlight %}

You can use the following date types:

* `:day`
* `:week`
* `:month`
* `:year`

Once you have the grouped results, you can enumerate by each result along with the group value, the number of objects that matched that group value, or both, using the following methods respectively:

{% highlight ruby %}
posts.each_with_groupby           { |post, group| }
posts.each_with_count             { |post, count| }
posts.each_with_groupby_and_count { |post, group, count| }
{% endhighlight %}

<h3 id="errors">Errors</h3>

At times, Sphinx will return no results, but sometimes that's because there was a problem with the actual query provided. When this happens, Sphinx includes the error message in the results.

You can access errors with `error` and test for errors with `error?`.

If an error is encountered, ThinkingSphinx will log it and then raise a `ThinkingSphinx::SphinxError` exception. You can tell ThinkingSphinx to ignore errors (though it will still log them) by passing in `:ignore_errors => true` or setting the property in your index with `set_property :ignore_errors => true`.

For example:

{% highlight ruby %}
r = Article.search '@doesntexist foo', :match_mode => :extended,
                                       :ignore_errors => true
r.error? # => true
{% endhighlight %}

Sphinx also issues warnings that you can test for with `warning?` and inspect with `warning`. No exception is raised on warnings.
