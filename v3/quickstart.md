---
layout: en
title: Quickstart
gem_version: v3
---

## A Quick Guide to Getting Setup with Thinking Sphinx

<div class="note">
  <p><strong>Note</strong>: This Guide is for Thinking Sphinx v3. If you can't use Ruby 1.9 or Rails/ActiveRecord 3.1 or newer, then you'll probably want <a href="quickstart_ts2.html">the old guide for v2 releases</a> instead.</p>
</div>

Firstly, you'll need to install both [Sphinx](installing_sphinx.html) and [Thinking Sphinx](installing_thinking_sphinx.html). While Sphinx is compiling, go read what [the difference is between fields and attributes](sphinx_basics.html) for Sphinx is. It's important stuff.

Once that's all done, it's time to set up an index on your model. In the example below, we're assuming the model is the Article class - and so we're going to put this index in `app/indices/article_index.rb` (the path matters, the file name is arbitrary, but should not be just the model's name).

{% highlight ruby %}
ThinkingSphinx::Index.define :article, :with => :real_time do
  # fields
  indexes subject, :sortable => true
  indexes content
  indexes author.name, :as => :author, :sortable => true

  # attributes
  has author_id,  :type => :integer
  has created_at, :type => :timestamp
  has updated_at, :type => :timestamp
end
{% endhighlight %}

The above definition is for a **real-time** index, and so fields and attributes refer to your model's methods.

You'll want to add [a callback](indexing.html#callbacks) to your model to ensure any changes flow through to Sphinx:

{% highlight ruby %}
# if your model is app/models/article.rb:
after_save ThinkingSphinx::RealTime.callback_for(:article)
{% endhighlight %}

The next step is to process your data (this task stops the Sphinx daemon if it is running, deletes existing Sphinx data, rewrites the Sphinx configuration file, starts the Sphinx daemon again, and then creates Sphinx documents for each indexed model instance):

{% highlight sh %}
rake ts:rebuild
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
