---
layout: en
title: Quickstart
---

## A Quick Guide to Getting Setup with Thinking Sphinx

<div class="note">
  <p><strong>Note</strong>: This Guide is for Thinking Sphinx v3. If you can't use Ruby 1.9 or Rails/ActiveRecord 3.1 or newer, then you'll probably want <a href="quickstart_ts2.html">the old guide for v2 releases</a> instead.</p>
</div>

Firstly, you'll need to install both [Sphinx](installing_sphinx.html) and [Thinking Sphinx](installing_thinking_sphinx.html). While Sphinx is compiling, go read what [the difference is between fields and attributes](sphinx_basics.html) for Sphinx is. It's important stuff.

Once that's all done, it's time to set up an index on your model. In the example below, we're assuming the model is the Article class - and so we're going to put this index in `app/indices/article_index.rb` (the path matters, but the file name is arbitrary).

{% highlight ruby %}
ThinkingSphinx::Index.define :article, :with => :active_record do
  # fields
  indexes subject, :sortable => true
  indexes content
  indexes author.name, :as => :author, :sortable => true

  # attributes
  has author_id, created_at, updated_at
end
{% endhighlight %}

Please don't forget that fields and attributes must reference columns from your model database tables, *not* methods. Sphinx talks directly to your database when indexing, and so the logic in your models doesn't have any impact.

The next step is to index your data:

{% highlight sh %}
rake ts:index
{% endhighlight %}

Once that's done, let's fire Sphinx up so we can query against it:

{% highlight sh %}
rake ts:start
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
