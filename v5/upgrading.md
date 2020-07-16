---
layout: en
title: Upgrading
gem_version: v5
redirect_from: "/upgrading.html"
---

## Upgrading Thinking Sphinx

The [release notes](https://github.com/pat/thinking-sphinx/releases) on GitHub are a good source for what notable changes have occured in each release - and especially breaking changes.

If you're using a version of Thinking Sphinx older than v4, please refer to [older documentation](../v4/upgrading.html).

The breaking changes since v4.x are:

* Sphinx 2.1 is no longer supported. You must use Sphinx 2.2.11 or newer.
* Ruby 2.3 (or older) is no longer supported. Arguably the code may still work in older Ruby versions, but it's only tested against 2.4+.
* Rails 4.1 (and older) is no longer supported. Arguably the code may still work in older Rails versions, but it's only tested against 4.2+.
* All indexed models require explicit callbacks (see below).

### Callbacks

Previously, Thinking Sphinx added automatic callbacks to every single ActiveRecord model, and then passed on relevant updates/deletions to Sphinx where possible (e.g. when using SQL-backed indices with deltas).

However, this is unnecessary overhead for models that aren't being indexed, so now you must add those callbacks yourself - just to the models that are being indexed:

{% highlight ruby %}
# if your indexed model is app/models/article.rb:
class Article < ApplicationRecord
  # if you're using SQL-backed indices:
  ThinkingSphinx::Callbacks.append(
    self, :behaviours => [:sql]
  )

  # if you're using SQL-backed indices with deltas:
  ThinkingSphinx::Callbacks.append(
    self, :behaviours => [:sql, :deltas]
  )

  # if you're using real-time indices
  ThinkingSphinx::Callbacks.append(
    self, :behaviours => [:real_time]
  )
  # this replaces:
  # after_save ThinkingSphinx::RealTime.callback_for(:article)
end
{% endhighlight %}

Models with real-time indices should have already had some callbacks added, but the above syntax replaces the old approach. The [indexing documentation](indexing.html#callbacks) covers further options for edge cases.
