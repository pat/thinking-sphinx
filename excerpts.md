---
layout: en
title: Excerpts
---

## Excerpts / Keyword Highlighting

<div class="note">
  <p><strong>Note</strong>: This feature is available in version 1.2 or later.</p>
</div>

When displaying search results, sometimes you may wish to highlight the query keywords in a record's text. This can be done using Sphinx's excerpts feature.

### Excerpts with Thinking Sphinx >= 3.0.0

Excerpts can be used in two different ways - you can either add a wrapper pane around each search result which provides access to an `excerpts` method, or build an `Excerpter` object yourself.

For the first approach, once you've constructed your search, you need to add the pane to ensure each search result gets wrapped appropriately:

{% highlight ruby %}
@articles = Article.search params[:query]
@articles.context[:panes] << ThinkingSphinx::Panes::ExcerptsPane
{% endhighlight %}

And then you can access excerpted text for any method on each search result:

{% highlight erb %}
<% @articles.each do |article| %>
  <div>
    <h3><%= article.excerpts.title %></h3>
    <div class="date"><%= article.created_at.to_s(:short) %></div>
    <%= article.excerpts.body %>
  </div>
<% end %>
{% endhighlight %}

Instead of wrapping every single search result to add that helper method, you can instead create an `Excerpter` instance and call out to that:

{% highlight ruby %}
@articles  = Article.search params[:query]
@excerpter = ThinkingSphinx::Excerpter.new 'article_core',
  params[:query]
{% endhighlight %}

And then in your views, call `excerpt!` for each piece of text you wish to calculate excerpts for:

{% highlight erb %}
<% @articles.each do |article| %>
  <div>
    <h3><%= @excerpter.excerpt! article.title %></h3>
    <div class="date"><%= article.created_at.to_s(:short) %></div>
    <%= @excerpter.excerpt! article.body %>
  </div>
<% end %>
{% endhighlight %}

If you want to change the default options of excerpts, you can pass them in via the `:excerpts` option in a search (for the first approach) or as a third argument when building an `Excerpter` in the second approach.

{% highlight ruby %}
@articles = Article.search params[:query], :excerpts => {
  :before_match    => '<span class="match">',
  :after_match     => '</span>',
  :chunk_separator => ' &#8230; ' # ellipsis
}
# or
@excerpter = ThinkingSphinx::Excerpter.new 'article_core',
  params[:query], {
    :before_match    => '<span class="match">',
    :after_match     => '</span>',
    :chunk_separator => ' &#8230; ' # ellipsis
  }
{% endhighlight %}

The full set of options are covered in [the Sphinx documentation](http://sphinxsearch.com/docs/current.html#api-func-buildexcerpts)

### Excerpts with Thinking Sphinx < 3.0.0

Thinking Sphinx automatically adds a method called `excerpts` to each search result, which can then query Sphinx for a specific column or method for the object, and return the highlighted version.

An example, working with a set of Articles, where we request the highlighted excerpts for the title and body:

{% highlight erb %}
<% @articles.each do |article| %>
  <div>
    <h3><%= article.excerpts.title %></h3>
    <div class="date"><%= article.created_at.to_s(:short) %></div>
    <%= textilize article.excerpts.body %>
  </div>
<% end %>
{% endhighlight %}

If you already have a method called `excerpts` on the search results, Thinking Sphinx will not overwrite it. However, you will need to use a slightly less elegant approach to generate the excerpted values:

{% highlight erb %}
<% @articles.each do |article| %>
  <div>
    <h3><%= @articles.excerpt_for(article.title) %></h3>
    <div class="date"><%= article.created_at.to_s(:short) %></div>
    <%= textilize @articles.excerpt_for(article.body) %>
  </div>
<% end %>
{% endhighlight %}

You can customise the excerpt settings by passing in `:excerpt_options` with your preferences:

{% highlight ruby %}
@articles = Article.search params[:query], :excerpt_options => {
  :before_match    => '<span class="match">',
  :after_match     => '</span>',
  :chunk_separator => ' &#8230; ' # ellipsis
}
{% endhighlight %}

The full set of options are covered in [the Sphinx documentation](http://sphinxsearch.com/docs/current.html#api-func-buildexcerpts)
