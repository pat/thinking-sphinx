---
layout: en
title:  Installing Thinking Sphinx
---

## Installing Thinking Sphinx (Rails 2.3)

If you're still stuck on Rails 2.3, then you can use a 1.4.x release of Thinking Sphinx. The latest of these is 1.4.14 - and it's unlikely any more 1.4.x releases will appear. Install it like you would any other gem - either manually:

{% highlight sh %}
gem install thinking-sphinx -v "~> 1.4.14"
{% endhighlight %}

Or by adding it to your Gemfile:

{% highlight ruby %}
gem 'thinking-sphinx', '~> 1.4.14'
{% endhighlight %}

Again, referring directly to the git respository is an option - please keep in mind that you'll want to lock to a commit from the v1 branch.

{% highlight ruby %}
gem 'thinking-sphinx', '~> 1.4.14',
  :git    => 'git://github.com/pat/thinking-sphinx.git',
  :branch => 'v1',
  :ref    => '94c61e9d79'
{% endhighlight %}

If you're setting your gem requirements in `config/environment.rb`, make sure you add it there too:

{% highlight ruby %}
config.gem 'thinking-sphinx', :version => '1.4.14'
{% endhighlight %}

And make sure you add this line to your `Rakefile` to ensure you can access the Thinking Sphinx rake tasks:

{% highlight ruby %}
begin
  require 'thinking_sphinx/tasks'
rescue LoadError
  puts "You can't load Thinking Sphinx tasks unless the thinking-sphinx gem is installed."
end
{% endhighlight %}

Installing Thinking Sphinx as a plugin is no longer recommended (and has not been for quite some time). In theory it should work for Rails 2.3 apps, but you'll need to manually clone the `v1` branch into `vendor/plugins`.

[Return to [Installing Thinking Sphinx]](/installing_thinking_sphinx.html)
