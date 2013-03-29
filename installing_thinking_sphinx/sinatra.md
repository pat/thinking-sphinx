---
layout: en
title:  Installing Thinking Sphinx
---

## Installing Thinking Sphinx (Sinatra, Padrino and others)

Follow the instructions for Rails (going by the version of ActiveRecord you're using), but then there's two more things to do:

Firstly, you'll need to add the Thinking Sphinx rake tasks to your Rakefile:

{% highlight ruby %}
require 'thinking_sphinx/tasks'
{% endhighlight %}

You will also need to make sure you require `thinking_sphinx/sinatra` instead of just `thinking_sphinx` - which is easily done in your Gemfile:

{% highlight ruby %}
gem 'thinking-sphinx', '~> 3.0.2',
  :require => 'thinking_sphinx/sinatra'
{% endhighlight %}

If you're using Thinking Sphinx v3 and you want to customise the environment and application root directory based on your own environment variables, you can do so with a few lines of Ruby code:

{% highlight ruby %}
framework = ThinkingSphinx::Framework::Plain.new
framework.environment = RACK_ENV       # Defaults to production
framework.root        = '/srv/www/app' # Defaults to Dir.pwd
ThinkingSphinx::Configuration.instance.framework = framework
{% endhighlight %}

[Return to [Installing Thinking Sphinx]](/installing_thinking_sphinx.html)
