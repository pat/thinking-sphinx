---
layout: en
title:  Installing Sphinx
gem_version: v4
---

## Installing Sphinx

Installing Sphinx can be done in various ways, depending on your operating system:

* [MacOS X](installing_sphinx/mac.html)
* [Linux](installing_sphinx/linux.html)
* [Windows](installing_sphinx/windows.html)

If you are using Thinking Sphinx version 3.0.0 or greater, please make sure you are using Sphinx 2.0.6 or newer. Sphinx 2.2.x is highly recommended for Thinking Sphinx v3.2.0 or newer.

<h3 id="compiling">Compiling Sphinx manually</h3>

If none of the prebuilt options are working for you, then you can always compile Sphinx yourself. [Download the code](http://www.sphinxsearch.com/downloads) from the Sphinx website, and then run these commands:

{% highlight sh %}
./configure --with-pgsql
make
sudo make install
{% endhighlight %}

You _can_ disable PostgreSQL support if you wish, just remove the `--with-pgsql` flag. MySQL support can also be disabled, but that's not recommended - Sphinx will not behave correctly with 3.x releases of Thinking Sphinx.

If the PostgreSQL headers and libraries aren't in your default paths, you can find out their location through the `pg_config` tool and then pass the value through when configuring:

{% highlight sh %}
./configure --with-pgsql=`pg_config --pkgincludedir`
{% endhighlight %}
