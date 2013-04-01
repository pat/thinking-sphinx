---
layout: en
title: Quickstart
---

## A Quick Guide to Getting Setup with Thinking Sphinx

<div class="note">
  <p><strong>Note</strong>: This Guide is for Thinking Sphinx v2 (though it applies to v1 as well). If you can, you should use v3 instead, as it's under active development. There's a version of <a href="quickstart.html">this guide for that</a> as well.</p>
</div>

Firstly, you'll need to install both [Sphinx](installing_sphinx.html) and [Thinking Sphinx](installing_thinking_sphinx.html). While Sphinx is compiling, go read what [the difference is between fields and attributes](sphinx_basics.html) for Sphinx is. It's important stuff.

Once that's all done, it's time to set up an index on your model. In the example below, we're assuming the model is the Article class.

{% highlight ruby %}
class Article < ActiveRecord::Base
  # ...

  define_index do
    # fields
    indexes subject, :sortable => true
    indexes content
    indexes author.name, :as => :author, :sortable => true

    # attributes
    has author_id, created_at, updated_at
  end

  # ...
end
{% endhighlight %}

Please don't forget that fields and attributes must reference columns from your model database tables, *not* methods. Sphinx talks directly to your database when indexing, and so the logic in your models doesn't have any impact.

The next step is to index your data:

{% highlight sh %}
rake thinking_sphinx:index
{% endhighlight %}

You will see a warning like the following – it’s safe to ignore, it’s just Sphinx being overly fussy.

{% highlight sh %}
distributed index 'article' can not be directly indexed; skipping.
{% endhighlight %}

Once that's done, let's fire Sphinx up so we can query against it:

{% highlight sh %}
rake thinking_sphinx:start
{% endhighlight %}

And now we can search!

{% highlight ruby %}
Article.search "topical issue"
Article.search "something", :order => :created_at,
  :sort_mode => :desc
Article.search "everything", :with => {:author_id => 5}
Article.search :conditions => {:subject => "Sphinx"}
{% endhighlight %}

Of course, that's an _extremely_ simple overview. It's definitely worth reading some more for a better understanding of the best ways to [index](indexing.html) and [search](searching.html).
