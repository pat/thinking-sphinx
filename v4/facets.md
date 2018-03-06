---
layout: en
title: Facets
gem_version: v4
---

## Faceted Searching

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: This page has not yet been updated with details for Thinking Sphinx v3, but you should have a look to this release note : https://github.com/pat/thinking-sphinx/releases/tag/v3.0.6  if you are using sphinx 2.1.1 or newer</p>

</div>

Facet Searches are search summaries - they provide a breakdown of result counts for each of the defined categories/facets.

### Defining Facets

You define facets inside the `define_index` method, within your model. To specify that a field or attribute should be considered a facet, explicitly label it using the `:facet` symbol.

{% highlight ruby %}
define_index do
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

To retrieve the ActiveRecord object results based on a selected facet(s), you can use the `for` method on a facet search result. When using the `for` method, Thinking Sphinx will automatically CRC any string values and use their respective `field_name_facet` attribute.

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

To disable the class facet, just set :class_facet to false.

{% highlight ruby %}
ThinkingSphinx.facets 'pancakes', :class_facet => false
{% endhighlight %}

And if you want absolutely every facet defined to be returned, whether or not they exist in all indexed models, set `:all_facets` to true.

{% highlight ruby %}
ThinkingSphinx.facets 'pancakes', :all_facets => true
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

### Facets Internals

When you define fields as facets, then an attribute with the same columns is created with the suffix `_facet`. If the field is a string (which is the case in most situations), then the value is converted to a CRC32 integer.

This CRC32 value is necessary as Sphinx currently doesn't support true string attributes, and thus we need a value to filter and group by when determining the facet results.

In the above examples, we have the author's name as a facet. This means there's an author_facet attribute, which you could filter on with the following query:

{% highlight ruby %}
Article.search :with => {:author_facet => 'John Watson'.to_crc32}
{% endhighlight %}

This means you can step around the `facets` and `for` calls to get results for specific facet arguments using `search` (again, using earlier examples):

{% highlight ruby %}
# all 'detection' articles with author 'Sherlock Holmes'
Article.search 'detection',
  :with => {:author_facet => 'Sherlock Holmes'.to_crc32}
{% endhighlight %}
