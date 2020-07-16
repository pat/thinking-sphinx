---
layout: en
title:  Installing Thinking Sphinx
gem_version: v5
disable_versions: true
redirect_from: "/installing_thinking_sphinx/ts3.html"
---

## Installing Thinking Sphinx

Thinking Sphinx v4 supports Rails 3.2, 4.x and 5.x (including 5.2).

<div class="note">
  <p><strong>Note</strong>: Thinking Sphinx v4.x (as documented here) is written for Ruby 2.2+. For older Ruby support, please refer to <a href="../../v3/installing_thinking_sphinx.html">previous versions of Thinking Sphinx</a>.</p>
</div>

Sphinx communicates via the MySQL protocol, and so you will need a MySQL gem to allow Thinking Sphinx to make queries to Sphinx.

* For standard (MRI) Ruby, use the `mysql2` gem (v0.3.13 or newer).
* For JRuby, use the `jdbc-mysql` gem (and Sphinx 2.1.2 or newer).

Even if you're using **PostgreSQL**, you will _still_ need to have the mysql2 gem installed (along with the `pg` gem too, of course).

Install them like you would any other gem - either manually:

{% highlight sh %}
gem install thinking-sphinx -v "~> 4.0"
gem install mysql2 -v "~> 0.4.10"
# or, for JRuby:
gem install jdbc-mysql -v 5.1.35
{% endhighlight %}

Or by adding them to your Gemfile:

{% highlight ruby %}
gem 'mysql2',          '~> 0.4.10', :platform => :ruby
gem 'jdbc-mysql',      '= 5.1.35',  :platform => :jruby
gem 'thinking-sphinx', '~> 4.0'
{% endhighlight %}

Versions of `jdbc-mysql` after 5.1.35 have altered behaviour that is not compatible with Sphinx.

You can also refer directly to the git repository - but if you're doing this, specifying the version, branch and commit reference is recommended so when you next go to upgrade the gem, it's clear what you were using (and perhaps why). The `develop` branch is where commits are pushed between version releases. The `master` branch is only updated when a new version is released.

{% highlight ruby %}
gem 'mysql2',          '~> 0.4.10', :platform => :ruby
gem 'jdbc-mysql',      '= 5.1.35',  :platform => :jruby
gem 'thinking-sphinx', '~> 4.0.0',
  :git    => 'https://github.com/pat/thinking-sphinx.git',
  :branch => 'develop',
  :ref    => 'cb45e1b1bf'
{% endhighlight %}

### Update .gitignore

When you [start Sphinx](https://freelancing-gods.com/thinking-sphinx/v4/rake_tasks.html), a new folder called `/db/sphinx` will be created. The files contained are equivalent to your database's data files, and should be *not* be committed into version control.

It's also recommended that you ignore the `config/ENV.sphinx.conf` files.

Add the following lines to your `.gitignore` file to ignore these files:

```
/db/sphinx
/config/*.sphinx.conf
```

### Using Thinking Sphinx with Unicorn

If you're using Unicorn as your web server, you'll want to ensure the connection pool is cleared after forking.

{% highlight ruby %}
after_fork do |server, worker|
  # Add this to an existing after_fork block if needed.
  ThinkingSphinx::Connection.pool.clear
end
{% endhighlight %}

[Return to [Installing Thinking Sphinx]](../installing_thinking_sphinx.html)
