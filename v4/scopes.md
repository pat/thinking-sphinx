---
layout: en
title: Sphinx Scopes
gem_version: v4
redirect_from: "/scopes.html"
---

## Sphinx Scopes

One of the popular features of ActiveRecord is scopes. You can try using them with searches, but they will not impact search results, just the SQL queries used to gather the ActiveRecord objects - Sphinx itself does not use SQL for querying.

However, Thinking Sphinx does have sphinx scopes, which work in pretty much the same manner.

### Adding Scopes

To add a scope to the model, use the `sphinx_scope` method. This should be called within the class definition, not the index definition. You will also need to include the `ThinkingSphinx::Scopes` module.

{% highlight ruby %}
class Article < ActiveRecord::Base
  include ThinkingSphinx::Scopes

  sphinx_scope(:latest_first) {
    {:order => 'created_at DESC, @relevance DESC'}
  }
  sphinx_scope(:by_name) { |name|
    {:conditions => {:name => name}}
  }
  # Here's an example using do/end instead of {} blocks.
  sphinx_scope(:by_point) do |lat, lng|
    {:geo => [lat, lng]}
  end

  # ...
end
{% endhighlight %}

Just like ActiveRecord scopes, you can use arguments if you need to.

### Using Scopes

Once you have set up your scopes, you can use them on your model, just like you would use ActiveRecord's scopes.

{% highlight ruby %}
@articles = Article.latest_first.search 'pancakes'
@articles = Article.latest_first.by_name('Puck').search 'pancakes'
{% endhighlight %}

The search call is optional, if you don't actually have any extra arguments to pass in.

{% highlight ruby %}
@articles = Article.latest_first.by_name('Puck')
{% endhighlight %}

Feel free to add to the chain at any point - Thinking Sphinx won't populate the search results until you actually need them.

{% highlight ruby %}
@articles = Article.latest_first
@articles = @articles.by_name(params[:name]) if params[:name]
{% endhighlight %}

### Default Scopes

The `default_sphinx_scope` method allows a sphinx scope to always be used when searching a model. This can be useful if all searches on a model require the scope is used.

{% highlight ruby %}
class Article < ActiveRecord::Base
  include ThinkingSphinx::Scopes

  sphinx_scope(:latest_first) {
    {:order => 'created_at DESC, @relevance DESC'}
  }

  default_sphinx_scope :latest_first
end
{% endhighlight %}
