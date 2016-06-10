---
layout: en
title: Rake Tasks
---

## Rake Tasks

### Processing real-time indices

To process your data in real-time indices, use the `ts:generate` task:

{% highlight sh %}
rake ts:generate
{% endhighlight %}

Callbacks in your models should catch changes to your data, but it's recommended you still run this task regularly to ensure your data is up-to-date.

Whenever you change your index structures, or add or remove indices, you will need to regenerate your Sphinx data from scratch. This can be done with the `ts:regenerate` task, which combines the following steps:

* Stop the Sphinx daemon (if it's running) (`ts:stop`)
* Delete existing Sphinx data files (`ts:clear_rt`)
* Rewrite the Sphinx configuration file (`ts:configure`)
* Start the Sphinx daemon (`ts:start`)
* Populate all your data (`ts:generate`)

### Processing SQL-backed indices

To process your data in SQL-backed indices, you can run the following rake task:

{% highlight sh %}
rake ts:index
{% endhighlight %}

The output of this task will look roughly like this:

{% highlight sh %}
Generating Configuration to \
  /path/to/RAILS_ROOT/config/development.sphinx.conf
indexer --config /path/to/RAILS_ROOT/config/development.sphinx.conf \
  --all
Sphinx 0.9.8-release (r1371)
Copyright (c) 2001-2008, Andrew Aksyonoff

using config file \
  '/path/to/RAILS_ROOT/config/development.sphinx.conf'...
indexing index 'article_core'...
collected 10 docs, 0.0 MB
collected 0 attr values
sorted 0.0 Mvalues, 100.0% done
sorted 0.0 Mhits, 100.0% done
total 10 docs, 142 bytes
total 0.101 sec, 1407.21 bytes/sec, 99.10 docs/sec
indexing index 'article_delta'...
collected 0 docs, 0.0 MB
collected 0 attr values
sorted 0.0 Mvalues, nan% done
total 0 docs, 0 bytes
total 0.010 sec, 0.00 bytes/sec, 0.00 docs/sec
distributed index 'article' can not be directly indexed; skipping.
{% endhighlight %}

This task, run normally, will also generate the configuration file for Sphinx. If you decide to make custom changes, then you can disable this generation by running the task with the INDEX_ONLY environment variable set to true:

{% highlight sh %}
INDEX_ONLY=true rake ts:index
{% endhighlight %}

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

When you make changes to your Sphinx index structure, you will need to stop and start Sphinx for these changes to take effect, as well as re-index the data. This is all wrapped up into a single task:

{% highlight sh %}
rake ts:rebuild
{% endhighlight %}
