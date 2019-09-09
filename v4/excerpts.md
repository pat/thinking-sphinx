---
layout: en
title: Excerpts
gem_version: v4
redirect_from: "/excerpts.html"
---

## Excerpts / Keyword Highlighting

When displaying search results, sometimes you may wish to highlight the query keywords in a record's text. This can be done using Sphinx's excerpts feature.

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

Instead of wrapping every single search result to add that helper method, you can instead create an `Excerpter` instance and call out to that. When constructing the excerpter, you will need to use the full index name (which includes the standard `_core` suffix that Thinking Sphinx appends to the model name).

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
