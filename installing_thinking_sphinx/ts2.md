---
layout: en
title:  Installing Thinking Sphinx
---

## Installing Thinking Sphinx (Rails 3.0)

If you're working on a Rails 3.0 application, then you'll need to use the version 2 releases of Thinking Sphinx - the latest (and likely last) is 2.0.14. Install it like you would any other gem - either manually:

{% highlight sh %}
gem install thinking-sphinx -v "~> 2.0.14"
{% endhighlight %}

Or by adding it to your Gemfile:

{% highlight ruby %}
gem 'thinking-sphinx', '~> 2.0.14'
{% endhighlight %}

You can also refer directly to the git repository - please keep in mind that you'll want to lock to a commit from the v2 branch.

{% highlight ruby %}
gem 'thinking-sphinx', '~> 2.0.14',
  :git    => 'git://github.com/pat/thinking-sphinx.git',
  :branch => 'v2',
  :ref    => '55788f7b96'
{% endhighlight %}

[Return to [Installing Thinking Sphinx]](/installing_thinking_sphinx.html)
