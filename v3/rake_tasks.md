---
layout: en
title: Rake Tasks
gem_version: v3
---

## Rake Tasks

Since v3.4.0, the rake tasks have been consolidated, and all of the tasks originally used for just SQL-backed indices now operate on both real-time and SQL-backed indices.

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

This feature has been in place since v3.1.0.

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
searchd --pidfile --config \
  /path/to/RAILS_ROOT/config/development.sphinx.conf
Sphinx 0.9.8-release (r1371)
Copyright (c) 2001-2008, Andrew Aksyonoff

using config file \
  '/path/to/RAILS_ROOT/config/development.sphinx.conf'...
Started successfully (pid 12928).
{% endhighlight %}

{% highlight sh %}
Sphinx 0.9.8-release (r1371)
Copyright (c) 2001-2008, Andrew Aksyonoff

using config file \
  '/path/to/RAILS_ROOT/config/development.sphinx.conf'...
stop: succesfully sent SIGTERM to pid 12928
Stopped search daemon (pid 12928).
{% endhighlight %}

### Rebuilding Sphinx Indexes

Whenever you change your index structures, or add or remove indices, you will need to regenerate your Sphinx data from scratch. This can be done with the `ts:rebuild` task, which combines the following steps:

* Stop the Sphinx daemon (if it's running) (`ts:stop`)
* Delete existing Sphinx data files (`ts:clear`)
* Rewrite the Sphinx configuration file (`ts:configure`)
* Populate data for SQL-backed indices (`ts:sql:index`)
* Start the Sphinx daemon (`ts:start`)
* Populate data for real-time indices (`ts:rt:index`)

### Legacy Real-Time Tasks

Prior to v3.4.0, the following tasks were used for managing real-time indices:

{% highlight sh %}
# For populating data - the equivalent of ts:index
rake ts:generate
# For rebuilding Sphinx's setup - the equivalent of ts:rebuild
rake ts:regenerate
{% endhighlight %}
