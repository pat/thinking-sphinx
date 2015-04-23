---
layout: en
title: Deployment
---

## Deployment

Once we've [installed Sphinx](installing_sphinx.html) and [installed ThinkingSphinx](installing_thinking_sphinx.html) on your production server, as well as setting up all of our indexes, we can deploy it to our production servers.

### Heroku

If you're using Heroku, then you cannot install Sphinx directly within your application. There is an add-on that allows you to use Sphinx with your Heroku apps though: [Flying Sphinx](http://flying-sphinx.com).

### Basics

Essentially, the following steps need to be performed for a deployment:

* stop Sphinx `searchd` (if it's running)
* generate Sphinx configuration
* start Sphinx `searchd`
* ensure index is regularly rebuilt

Configuring Sphinx for our production environment includes setting where the PID file and the index files are stored. In your `config/thinking_sphinx.yml` file, set up the following additional parameters:

{% highlight yaml %}
production:
  pid_file: /path/to/app/shared/tmp/searchd.pid
  indices_location: /path/to/app/shared/db/sphinx
  configuration_file: /path/to/app/shared/production.sphinx.conf
  binlog_path: /path/to/app/shared/binlog
{% endhighlight %}

Please make sure all of the above files (configuration file, pid file, index files, binlog path) are located in a **shared directory** (instead of a directory tied to a specific deployed release). Otherwise, running rake tasks will become difficult and unreliable.

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: If you are using an older version of Thinking Sphinx, then the file is <code>config/sphinx.yml</code>, and the second setting is <code>searchd_file_path</code> (and the third and fourth can be skipped):</p>

{% highlight yaml %}
production:
  pid_file: /path/to/app/shared/tmp/searchd.pid
  searchd_file_path: /path/to/app/shared/db/sphinx
{% endhighlight %}
</div>

You'll want to make sure that the application shared folder has `db` and `tmp` subdirectories (or whatever is appropriate for your settings). You'll also want to double check the permissions of these folders so that the user the application and searchd both runs as can write to both folders.

Before deploying, we generally assume that the Sphinx `searchd` search daemon is running. You may need to manually configure and run the daemon the first deployment with ThinkingSphinx support added.

### Deploying With Capistrano

Deploying via Capistrano is simplified by the included recipe file that comes with the ThinkingSphinx plugin.

The first step is to include the recipe in order to define the necessary tasks for us:

{% highlight ruby %}
# If you're using Thinking Sphinx 3.x or newer:
require 'thinking_sphinx/capistrano'
# If you're using Thinking Sphinx 2.x as a gem (Rails 3 way):
require 'thinking_sphinx/deploy/capistrano'
# If you're using Thinking Sphinx 1.x or 2.x as a plugin:
require 'vendor/plugins/thinking-sphinx/recipes/thinking_sphinx'
{% endhighlight %}

Now, configure Thinking Sphinx 3.x as follows

{% highlight ruby %}
namespace :sphinx do
  desc "Symlink Sphinx indexes"
  task :symlink_indexes do
    on roles(:app) do
      sudo "ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx"
    end
  end

  desc "Activate Sphinx"
  task :activate do
    on roles(:app) do
      within release_path do
        as fetch :user do
          with rails_env: fetch(:rails_env) do
            execute :rake, 'ts:configure'
            execute :rake, 'ts:index'
            execute :rake, 'ts:start'
          end
        end
      end
    end
  end

  desc "Stop Sphinx"
  task :stop do
    on roles(:app) do
      within release_path do
        as fetch :user do
          with rails_env: fetch(:rails_env) do
            execute :rake, 'ts:stop'
          end
        end
      end
    end
  end
end

namespace :deploy do

  # THINKING SPHINX
  before 'deploy:started', 'sphinx:stop'
  after 'deploy:published', 'sphinx:symlink_indexes'
  after 'deploy:finished', 'sphinx:activate'
  # THINKING SPHINX END

end
{% endhighlight %}

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: If you are using an older version of Thinking Sphinx and you've not set your paths up to be outside of a specific deployed release directory, then you'll need to add some extra code to your <code>deploy.rb</code> file to make sure that Sphinx is properly configured, indexed, and started on each deploy.</p>

  <p>It is far better, though, to use the configuration options mentioned above and avoid release-specific paths.</p>

{% highlight ruby %}
before 'deploy:update_code', 'thinking_sphinx:stop'
after  'deploy:update_code', 'thinking_sphinx:start'

namespace :sphinx do
  desc "Symlink Sphinx indexes"
  task :symlink_indexes, :roles => [:app] do
    run "ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx"
  end
end

after 'deploy:finalize_update', 'sphinx:symlink_indexes'
{% endhighlight %}

<p>The above makes sure we stop the Sphinx <code>searchd</code> search daemon before we update the code. After the code is updated, we reconfigure Sphinx and then restart. You should also setup a `cron` job to keep the indexes up-to-date.</p>
</div>

### Regularly Processing the Indices

One of the side effects of the Sphinx indexing methodology is that it is necessary to regularly process your indices in order to be able to search with recent changes. In order to do this, we set up a `cron` job to run the appropriate command.

In your `/etc/crontab` file, add the following line to the bottom:

{% highlight bash %}
0 * * * * deploy  cd /path/to/app/current && /usr/local/bin/rake ts:index RAILS_ENV=production
{% endhighlight %}

Also, you can use the [whenever](https://github.com/javan/whenever) gem to control your Cron tasks from the Rails app. The same job for `whenever` in `config/schedule.rb` looks like this:

{% highlight ruby %}
every 60.minutes do
  rake "ts:index"
end
{% endhighlight %}
