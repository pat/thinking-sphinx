---
layout: en
title:  Installing Sphinx on MacOS X
gem_version: v4
redirect_from: "/installing_sphinx/mac.html"
---

## Installing Sphinx on MacOS X

### Using Homebrew

Installing Sphinx with Homebrew is pretty easy - and it'll automatically detect whether you have MySQL and/or PostgreSQL installed and ensure Sphinx supports either/both when compiling.

{% highlight sh %}
brew install sphinx
{% endhighlight %}

At the time of writing, Homebrew will install Sphinx 2.2.11. Make sure you do have MySQL installed so the SphinxQL/mysql41 protocol behaves correctly.

If you've installed MySQL _after_ installing Sphinx, you'll need to re-install Sphinx. This can be done like so:

{% highlight sh %}
brew remove sphinx
brew install sphinx --with-mysql
{% endhighlight %}

### Using MacPorts

Much like Homebrew, MacPorts will automatically detect whether it should compile Sphinx with MySQL and/or PostgreSQL support, and currently defaults to Sphinx 2.2.11 as well.

{% highlight sh %}
port install sphinx
{% endhighlight %}

You may need to run the above command with sudo depending on your permissions setup.

### Other options

If you don't have either Homebrew or MacPorts installed, then you could install either of them, or just [compile Sphinx yourself](../installing_sphinx.html#compiling). This will require the MacOS Developer Tools (but then, so will either of the package managers), but should work without much hassle.

[Return to [Installing Sphinx]](../installing_sphinx.html)
