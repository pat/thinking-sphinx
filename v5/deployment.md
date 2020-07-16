---
layout: en
title: Deployment
gem_version: v5
redirect_from: "/deployment.html"
---

## Deployment

Once we've [installed Sphinx](installing_sphinx.html) and [installed ThinkingSphinx](installing_thinking_sphinx.html) on your production server, as well as setting up all of our indexes, we can deploy it to our production servers.

### Heroku

If you're using Heroku, then you cannot install Sphinx directly within your application. There is an add-on that allows you to use Sphinx with your Heroku apps though, and has streamlined integration with Thinking Sphinx: [Flying Sphinx](http://flying-sphinx.com).

### Basics

Configuring Sphinx for our production environment includes setting where the PID file and the index files are stored. In your `config/thinking_sphinx.yml` file, set up the following additional parameters:

{% highlight yaml %}
production:
  pid_file: /path/to/app/shared/tmp/searchd.pid
  indices_location: /path/to/app/shared/db/sphinx
  configuration_file: /path/to/app/shared/production.sphinx.conf
  binlog_path: /path/to/app/shared/binlog
{% endhighlight %}

Please make sure all of the above files (configuration file, pid file, index files, binlog path) are located in a **shared directory** (instead of a directory tied to a specific deployed release). Otherwise, running rake tasks will become difficult and unreliable.

Symlinked directories are **strongly discouraged** as an alternative to (or in combination with) shared paths. Symlinked paths can be translated to release-specific paths when generating configuration, and this can lead to data inconsistency problems.

You'll want to make sure that the application shared folder has `db` and `tmp` subdirectories (or whatever is appropriate for your settings). You'll also want to double check the permissions of these folders so that the user the application and searchd both runs as can write to both folders.

Before deploying, we generally assume that the Sphinx `searchd` search daemon is running. You may need to manually configure and run the daemon the first deployment with ThinkingSphinx support added.

### Deploying With Capistrano

Deploying via Capistrano is simplified by the included recipe file that comes within Thinking Sphinx for some helpful default tasks:

{% highlight ruby %}
require 'thinking_sphinx/capistrano'
{% endhighlight %}

### Regularly Processing the Indices

One of the side effects of the Sphinx SQL-backed indexing methodology is that it is necessary to regularly process your indices in order to be able to search with recent changes. In order to do this, we set up a `cron` job to run the appropriate command.

In your `/etc/crontab` file, add the following line to the bottom:

{% highlight bash %}
0 * * * * deploy  cd /path/to/app/current && bundle exec rake ts:index RAILS_ENV=production
{% endhighlight %}

Also, you can use the [whenever](https://github.com/javan/whenever) gem to control your Cron tasks from the Rails app. The same job for `whenever` in `config/schedule.rb` looks like this:

{% highlight ruby %}
every 60.minutes do
  rake "ts:index"
end
{% endhighlight %}
