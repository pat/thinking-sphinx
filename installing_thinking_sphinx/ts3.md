---
layout: en
title:  Installing Thinking Sphinx
---

## Installing Thinking Sphinx (Rails 3.1 or Newer)

<div class="note">
  <strong>Note</strong>: Thinking Sphinx v3.x (as documented here) is written for Ruby 1.9. If you are using Ruby 1.8.7 (or equivalent), please use a v2 release - covered in <a href="/installing_thinking_sphinx/ts2.html">the Rails 3.0 installation instructions</a>.
</div>

<div class="note">
  <strong>Note</strong>: Thinking Sphinx v3 is a complete rewrite from previous versions, and there are many small and big changes. These are noted accordingly in this documentation.
</div>

If you're using Rails 3.1, 3.2 or 4.0, then you should use the version 3 releases of Thinking Sphinx. Install it like you would any other gem - either manually:

{% highlight sh %}
gem install thinking-sphinx -v "~> 3.0.2"
{% endhighlight %}

Or by adding it to your Gemfile:

{% highlight ruby %}
gem 'thinking-sphinx', '~> 3.0.2'
{% endhighlight %}

You can also refer directly to the git repository - but if you're doing this, specifying the version, branch and commit reference is recommended so when you next go to upgrade the gem, it's clear what you were using (and perhaps why).

{% highlight ruby %}
gem 'thinking-sphinx', '~> 3.0.2',
  :git    => 'git://github.com/pat/thinking-sphinx.git',
  :branch => 'master',
  :ref    => 'ec658bff04'
{% endhighlight %}

At the time of writing this, Rails 4.0.0.beta1 is available. The only version of Thinking Sphinx that currently supports Rails 4 is 3.0.2 - though there may still be changes to both Rails and Thinking Sphinx before the proper 4.0.0 version is released.

[Return to [Installing Thinking Sphinx]](/installing_thinking_sphinx.html)
