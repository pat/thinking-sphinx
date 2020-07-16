---
layout: en
title:  Installing Sphinx
gem_version: v5
redirect_from: "/installing_sphinx.html"
---

## Installing Sphinx

Installing Sphinx can be done in various ways, depending on your operating system:

* [MacOS X](installing_sphinx/mac.html)
* [Linux](installing_sphinx/linux.html)
* [Windows](installing_sphinx/windows.html)

Please make sure you are using Sphinx 2.2.11 or newer.

Sphinx v3.x releases will work if you're using real-time indices, or you're using MySQL as your database. There are known issues with PostgreSQL and Sphinx 3.x, and at the time of writing (with Sphinx v3.3.1) they are not yet resolved.

<h3 id="compiling">Compiling Sphinx manually</h3>

If none of the prebuilt options are working for you, then you can always compile Sphinx yourself - but only Sphinx v2.2.11, as the v3 source is not available. [Download the code](http://www.sphinxsearch.com/downloads) from the Sphinx website, and then run these commands:

{% highlight sh %}
./configure --with-pgsql --with-mysql
make
sudo make install
{% endhighlight %}

You _can_ disable PostgreSQL support if you wish, just remove the `--with-pgsql` flag. MySQL support should not be disabled, as Thinking Sphinx communicates with Sphinx via the MySQL protocol.

If the PostgreSQL headers and libraries aren't in your default paths, you can find out their location through the `pg_config` tool and then pass the value through when configuring:

{% highlight sh %}
./configure --with-mysql --with-pgsql=`pg_config --pkgincludedir`
{% endhighlight %}
