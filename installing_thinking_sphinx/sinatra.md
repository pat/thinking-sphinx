---
layout: en
title:  Installing Thinking Sphinx
---

## Installing Thinking Sphinx (Sinatra, Padrino and others)

Follow the instructions for Rails (going by the version of ActiveRecord you're using), but then there's two more things to do:

Firstly, you'll need to add the Thinking Sphinx rake tasks to your Rakefile:

{% highlight ruby %}
task :environment do
  Sinatra::Application.environment = 'production' # or ENV['RACK_ENV'] if you're using rack
end
require '/path/to/your/app.rb'

require 'thinking_sphinx/tasks'
{% endhighlight %}

You will also need to make sure you require `thinking_sphinx/sinatra` instead of just `thinking_sphinx` - which is easily done in your Gemfile:

{% highlight ruby %}
gem 'thinking-sphinx', '~> 3.2.0',
  :require => 'thinking_sphinx/sinatra'
{% endhighlight %}

If you're using Thinking Sphinx v3 and you want to customise the environment and application root directory based on your own environment variables, you can do so with a few lines of Ruby code:

{% highlight ruby %}
framework = ThinkingSphinx::Frameworks::Plain.new
framework.environment = RACK_ENV       # Defaults to production
framework.root        = '/srv/www/app' # Defaults to Dir.pwd
ThinkingSphinx::Configuration.instance.framework = framework
{% endhighlight %}

[Return to [Installing Thinking Sphinx]](/thinking-sphinx/installing_thinking_sphinx.html)
