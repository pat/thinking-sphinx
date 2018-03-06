---
layout: en
title: Advanced Sphinx Configuration
gem_version: v4
redirect_from: "/advanced_config.html"
---

## Advanced Sphinx Configuration

Thinking Sphinx provides a good set of defaults out of the box, and for some people, those options are exactly what they need. Sometimes, though, you may need to customise how Sphinx works - and this can usually be done by adding some settings to a file named `thinking_sphinx.yml` in your `config` directory. Much like database.yml, settings are defined for each environment. Here's an example:

{% highlight yaml %}
development:
  mysql41: 9312
test:
  mysql41: 9313
production:
  mysql41: 9312
{% endhighlight %}

Now, [Sphinx has a _lot_ of different settings](http://www.sphinxsearch.com/docs/current.html#confgroup-index) you can play with, and they're pretty much all supported by Thinking Sphinx as well. Documentation will be added here for them over time, but in a pinch, it should be pretty easy to guess the syntax for the YAML file for each setting.

### Index File Location

You can customise the location of your Sphinx index files using the `indices_location` option.

Thinking Sphinx defaults to putting these files in db/sphinx/ENVIRONMENT - which makes life easier if you're running integration tests with a live Sphinx setup. It's worth keeping this in mind and ensuring your file locations are unique for each environment when they share a machine. Indeed, you'll probably only want to change this value on your production machine.

{% highlight yaml %}
production:
  indices_location: "/var/www/my_app/shared/sphinx"
# ... repeat for other environments if necessary
{% endhighlight %}

### Configuration, PID and Log File Locations

In the same vein as the above setting, you can nominate custom locations for your configuration, log and pid files.

Here's some example syntax, using Thinking Sphinx's defaults. Uppercase words are placeholders for system variables in the example only - you can't actually use them in your YAML file.

{% highlight yaml %}
development:
  configuration_file: "RAILS_ROOT/config/ENVIRONMENT.sphinx.conf"
  log: "RAILS_ROOT/log/searchd.log"
  query_log: "RAILS_ROOT/log/searchd.query.log"
  pid_file: "RAILS_ROOT/log/searchd.ENVIRONMENT.pid"
# ... repeat for other environments
{% endhighlight %}

<h3 id="daemon-address">Daemon Address and Port</h3>

If your Sphinx Daemon (also known as *searchd*) is running on a different machine or port, you're going to need to tell Thinking Sphinx the critical details:

{% highlight yaml %}
production:
  address: 10.0.0.4
  mysql41: 3200
# ... repeat for other environments if necessary
{% endhighlight %}

### Indexer Memory Usage

Sphinx indexes your data using the `indexer` command-line tool. This tool runs with a fixed memory limit - defaulting to 64 megabytes. You can change this to something else if you'd like - the more memory, the faster your indexes will be processed.

{% highlight yaml %}
development:
  mem_limit: 128M
# ... repeat for other environments
{% endhighlight %}

### Word Stemming / Morphology

By default, Sphinx and Thinking Sphinx doesn't get too smart about the words you're searching for - it assumes you know exactly what you're after. However, sometimes you may want it to recognise that certain words share pretty much the same meaning. For example: think and thinking.

To enable this kind of behaviour, you need to specify a morphology (or stemming library) to Sphinx. It comes with English (stem_en) and Russian (stem_ru) built-in. You can also use other stemmers via [Snowball's](http://snowball.tartarus.org/) libstemmer library. Have a read of [Sphinx's documentation](http://sphinxsearch.com/docs/current.html#conf-morphology) for more clues.

{% highlight yaml %}
development:
  morphology: stem_en
# ... repeat for other environments
{% endhighlight %}

### Wildcard/Star Syntax

If you're using Sphinx 2.2.2 or newer, wildcard syntax will be respected by default (though you'll also need infixes or prefixes, as covered in the next section).

If you're using an older version of Sphinx, then you can enable wildcard syntax using the `enable_star` option:

{% highlight yaml %}
development:
  enable_star: true
# ... repeat for other environments
{% endhighlight %}

### Infix and Prefix Indexing

If you want partial word matching, then you're going to need to tell Sphinx to either index prefixes (the beginnings of words) or infixes (substrings of words). You **cannot enable both** at once, though.

You need to tell Sphinx what the minimum infix or prefix length is - the smaller the number is, the larger your index gets. If you set it to zero, though, that disables this feature. If you want absolutely everything, down to the last character, then set min_infix_len to 1 - but be prepared for the performance hit.

{% highlight yaml %}
development:
  min_infix_len: 3
  # OR
  min_prefix_len: 3
# ... repeat for other environments
{% endhighlight %}

### Character Sets and Tables

By default, Sphinx and Thinking Sphinx use the UTF-8 character set. If you're using an older version of Sphinx and prefer Sphinx's inbuild sbcs encoding, you'll need to specify it via the charset_type setting:

{% highlight yaml %}
development:
  charset_type: sbcs
# ... repeat for other environments
{% endhighlight %}

This changest the default character mappings, which you can read about in [the Sphinx documentation](http://sphinxsearch.com/docs/current.html#conf-charset-table). You can also set your own character mappings - which is recommended when using UTF-8 - to include other characters. [James Healy](http://yob.id.au/) has posted [his extensive settings](http://yob.id.au/blog/2008/05/08/thinking_sphinx_and_unicode/) which cover most (if not all) accented characters. If you don't want to click through, it's all done via the charset_table setting:

{% highlight yaml %}
development:
  charset_table: "0..9, A..Z->a..z, _, a..z, \
U+410..U+42F->U+430..U+44F, U+430..U+44F"
# ... repeat for other environments
{% endhighlight %}

<h3 id="large-result-sets">Large Result Sets</h3>

To keep searching fast, Sphinx has a default limit of 1000 records being available via pagination, even if there are more matches than that. The reasons for this limit are [discussed in the Sphinx documentation](http://www.sphinxsearch.com/docs/current.html#conf-max-matches).

However, you can change this value. Firstly, in your `config/thinking_sphinx.yml` file, you need to set max_matches to your upper limit:

{% highlight yaml %}
development:
  max_matches: 10000
# ... repeat for other environments
{% endhighlight %}

Don't forget to reconfigure and restart your Sphinx daemon so it is aware of the change.

{% highlight sh %}
rake ts:stop ts:configure ts:start
{% endhighlight %}

And you also need to specify it in your searches (Sphinx doesn't assume you want the higher number by default):

{% highlight ruby %}
Article.search 'pancakes', :max_matches => 10_000
{% endhighlight %}

This does not mean you will get 10,000 results returned in one request, but you can paginate up to the ten-thousandth result. If you want them all at once (which will be slow, because you're asking Rails to instantiate 10,000 records), use the `per_page` option.

{% highlight ruby %}
Article.search 'pancakes',
  :max_matches => 10_000,
  :per_page    => 10_000
{% endhighlight %}

### Word Forms, Exceptions, and Stop Words

To configure Thinking Sphinx for any of these features, simply specify the path to the appropriate file in your `config/thinking_sphinx.yml` file:

{% highlight yaml %}
development:
  wordforms: "/full/path/to/wordforms.txt"
  exceptions: "/full/path/to/exceptions.txt"
  stopwords: "/full/path/to/stopwords.txt"
# ... repeat for other environments
{% endhighlight %}

For full details on what these features actually do, please refer to the Sphinx documentation.
