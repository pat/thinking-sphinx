---
layout: en
title: Search Middleware
gem_version: v4
disable_versions: true
redirect_from: "/middleware.html"
---

## Search Middleware

Much like Rack and other HTTP libraries, Thinking Sphinx's searches are constructed and processed by a set of middleware. They take the provided search parameters, generate a query that Sphinx understands, makes the search request, and then translate the resulting values back into ActiveRecord instances.

Each middleware must be a class that is initialized with an app object, has an instance method `call` which accepts an array of search contexts, and that method should then invoke `app.call(contexts)` to continue the chain.

{% highlight ruby %}
class CustomMiddleware
  def initialize(app)
    @app = app
  end

  def call(contexts)
    # Do custom things here. Perhaps set default search options,
    # or modifications based on the broader application
    # environment, or whatever
    # …

    # … and then, keep the request going:
    app.call contexts
  end

  private

  attr_reader :app
end
{% endhighlight %}

To add custom middleware into the mix, you can either do this in an initializer so it affects _all_ searches:

{% highlight ruby %}
# For searches that return ActiveRecord objects
ThinkingSphinx::Middlewares::DEFAULT.insert(0, CustomMiddleware)
# For searches that return raw Sphinx results
ThinkingSphinx::Middlewares::RAW_ONLY.insert(0, CustomMiddleware)
# For searches that return ActiveRecord primary keys
ThinkingSphinx::Middlewares::IDS_ONLY.insert(0, CustomMiddleware)
{% endhighlight %}

Or, you can specify a custom middleware stack on a per-search basis:

{% highlight ruby %}
# A modification of the DEFAULT set:
middlewares = ::Middleware::Builder.new do
  use CustomMiddleware
  use ThinkingSphinx::Middlewares::StaleIdFilter
  ThinkingSphinx::Middlewares.use self,
    ThinkingSphinx::Middlewares::BASE_MIDDLEWARES
  use ThinkingSphinx::Middlewares::ActiveRecordTranslator
  use ThinkingSphinx::Middlewares::StaleIdChecker
  use ThinkingSphinx::Middlewares::Glazier
end

Article.search "foo", :middleware => middlewares
{% endhighlight %}

The best place to understand the existing set of middleware is by reading [the source code](https://github.com/pat/thinking-sphinx/blob/develop/lib/thinking_sphinx/middlewares.rb).
