---
layout: en
title: Facets
gem_version: v4
redirect_from: "/facets.html"
---

## Faceted Searching

Facet Searches are search summaries - they provide a breakdown of result counts for each of the defined categories/facets.

### Defining Facets

You define facets inside your index definition. To specify that a field or attribute should be considered a facet, explicitly label it using the `:facet` symbol.

{% highlight ruby %}
ThinkingSphinx::Index.define :article, :with => :active_record do
  # ...
  indexes author.name, :as => :author, :facet => true

  # ...
  has category_id, :facet => true
end
{% endhighlight %}

You _cannot_ use custom SQL statements as string facet sources. Thinking Sphinx is unable to interpret the SQL within the context of the model, and strings can't be stored as strings when they are attributes in Sphinx.

Even if you define your facet as a field, Thinking Sphinx duplicates it into an attribute, because facets are essentially grouped searches, and grouping can only be done with attributes.

### Querying Facets

Facets are available through the facets class method on all ActiveRecord models that have Sphinx indexes, and are returned as a subclass of Hash.

{% highlight ruby %}
Article.facets # =>
{
  :author => {
    "Sherlock Holmes" => 3,
    "John Watson"     => 10
  },
  :category_id => {
    12 => 4,
    42 => 7,
    47 => 2
  }
}
{% endhighlight %}

The facets method accepts the same options as the `search` method.

{% highlight ruby %}
Article.facets 'pancakes'
Article.facets :conditions => {:author => 'John Watson'}
Artcile.facets :with => {:category_id => 12}
{% endhighlight %}

You can also explicitly request just certain facets:

{% highlight ruby %}
Article.facets :facets => [:author]
{% endhighlight %}

To retrieve the ActiveRecord object results based on a selected facet(s), you can use the `for` method on a facet search result. Please note that you'll need Sphinx 2.2 for filtering on string attributes.

{% highlight ruby %}
# Facets for all articles matching 'detection'
@facets   = Article.facets('detection')
# All 'detection' articles with author 'Sherlock Holmes'
@articles = @facets.for(:author => 'Sherlock Holmes')
{% endhighlight %}

If you call @for@ without any arguments, then all the matching search results for the initial facet query are returned.

{% highlight ruby %}
@facets   = Article.facets('pancakes')
@articles = @facets.for
{% endhighlight %}

### Global Facets

Faceted searches can be made across all indexed models, using the same arguments.

{% highlight ruby %}
ThinkingSphinx.facets 'pancakes'
{% endhighlight %}

By default, Thinking Sphinx does not request _all_ possible facets, only those common to all models. If you don't have any of your own facets, then this will just be the class facet, providing a summary of the matches per model.

{% highlight ruby %}
ThinkingSphinx.facets 'pancakes' # =>
{
  :class => {
    'Article' => 13,
    'User'    => 3,
    'Recipe'  => 23
  }
}
{% endhighlight %}

### Displaying Facets

To get you started, here is a basic example displaying the facet options in a view:

{% highlight erb %}
<% @facets.each do |facet, facet_options| %>
  <h5><%= facet %></h5>
  <ul>
  <% facet_options.each do |option, count| %>
    <li><%= link_to "#{option} (#{count})",
      :params => {facet => option, :page => 1} %></li>
  <% end %>
  </ul>
<% end %>
{% endhighlight %}

Thinking Sphinx does not sort facet results. If this is what you'd prefer, then one option is to use Ruby's `sort` or `sort_by` methods. Keep in mind you will then get arrays of two values (the facet value, and the facet count), instead of a hash key/value pair.

{% highlight ruby %}
@facets[:author].sort
# Sort by strings to avoid exceptions
@facets[:author].sort_by { |a| a[0].to_s }
{% endhighlight %}
