---
layout: en
title: Rake Tasks
gem_version: v5
redirect_from: "/rake_tasks.html"
---

## Rake Tasks

<div class="note">
  <p><strong>Note</strong>: Since v3.4.0, the rake tasks have been consolidated, and all of the tasks originally used for just SQL-backed indices now operate on both real-time and SQL-backed indices.</p>
</div>

### Processing indices

To process your data in indices, use the `ts:index` task:

{% highlight sh %}
rake ts:index
{% endhighlight %}

Callbacks in your models should catch changes to your data with real-time indices, but it's recommended you still run this task regularly to ensure your data is up-to-date.

It's also worth noting that this task, run normally, will also generate the configuration file for Sphinx. If you decide to make custom changes, then you can disable this generation by running the task with the INDEX_ONLY environment variable set to true:

{% highlight sh %}
INDEX_ONLY=true rake ts:index
{% endhighlight %}

#### Index Guard Files

Any given SQL-backed index can not be processed more than once concurrently. To avoid multiple indexing requests, Thinking Sphinx adds a lock file in the indices directory while indexing occurs, named `ts-INDEXNAME.tmp`.

In rare cases (generally when the parent process crashes completely), orphan lock files may remain - these are safe to remove if no indexing is occured. If you're finding some of your indices aren't being processed reliably, checking for these index files is recommended.

### Generating the Configuration File

If you need to just generate the configuration file, without indexing (something that can be useful when deploying), here's the task to do it:

{% highlight sh %}
rake ts:configure
{% endhighlight %}

Expected output:

{% highlight sh %}
Generating Configuration to \
  /path/to/RAILS_ROOT/config/development.sphinx.conf
{% endhighlight %}

### Starting and Stopping Sphinx

If you actually want to search against the indexed data, then you'll need Sphinx's searchd daemon to be running. This can be controlled using the following tasks:

{% highlight sh %}
rake ts:start
rake ts:stop
{% endhighlight %}

Expected outputs:

{% highlight sh %}
Sphinx 2.2.11-id64-release (95ae9a6)
Copyright (c) 2001-2016, Andrew Aksyonoff
Copyright (c) 2008-2016, Sphinx Technologies Inc (http://sphinxsearch.com)

using config file '/path/to/RAILS_ROOT/config/development.sphinx.conf'...
WARNING: key 'charset_type' was permanently removed from Sphinx configuration. Refer to documentation for details.
listening on 127.0.0.1:9322
{% endhighlight %}

{% highlight sh %}
Sphinx 2.2.11-id64-release (95ae9a6)
Copyright (c) 2001-2016, Andrew Aksyonoff
Copyright (c) 2008-2016, Sphinx Technologies Inc (http://sphinxsearch.com)

using config file '/path/to/RAILS_ROOT/config/development.sphinx.conf'...
WARNING: key 'charset_type' was permanently removed from Sphinx configuration. Refer to documentation for details.
stop: successfully sent SIGTERM to pid 70509
Stopped searchd daemon (pid: 70509).
{% endhighlight %}

### Rebuilding Sphinx Indexes

Whenever you change your index structures, or add or remove indices, you will need to regenerate your Sphinx data from scratch. This can be done with the `ts:rebuild` task, which combines the following steps:

* Stop the Sphinx daemon (if it's running) (`ts:stop`)
* Delete existing Sphinx data files (`ts:clear`)
* Rewrite the Sphinx configuration file (`ts:configure`)
* Populate data for SQL-backed indices (`ts:sql:index`)
* Start the Sphinx daemon (`ts:start`)
* Populate data for real-time indices (`ts:rt:index`)
