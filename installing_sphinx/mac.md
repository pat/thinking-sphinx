---
layout: en
title:  Installing Sphinx on MacOS X
---

## Installing Sphinx on MacOS X

### Using Homebrew

Installing Sphinx with Homebrew is pretty easy - and it'll automatically detect whether you have MySQL and/or PostgreSQL installed and ensure Sphinx supports either/both when compiling.

{% highlight sh %}
brew install sphinx
{% endhighlight %}

At the time of writing, Homebrew will install Sphinx 2.0.6 (which is the oldest version allowed if you're running Thinking Sphinx v3.x). Make sure you do have MySQL installed so the SphinxQL/mysql41 protocol behaves correctly.

Notice : if you're using MySQL, the thinking-sphinx gem won't work because it needs to use MySQL libraries.

If you managed to screw up the first time, uninstall sphinx first:

{% highlight sh %}
brew remove sphinx
{% endhighlight %}

and then :
{% highlight sh %}
brew install sphinx --mysql
{% endhighlight %}

### Using MacPorts

Much like Homebrew, MacPorts will automatically detect whether it should compile Sphinx with MySQL and/or PostgreSQL support, and currently defaults to Sphinx 2.0.6 as well.

{% highlight sh %}
port install sphinx
{% endhighlight %}

You may need to run the above command with sudo depending on your permissions setup.

### Other options

If you don't have either Homebrew or MacPorts installed, then you could install either of them, or just [compile Sphinx yourself](/thinking-sphinx/installing_sphinx.html#compiling). This will require the MacOS Developer Tools (but then, so will either of the package managers), but should work without much hassle.

[Return to [Installing Sphinx]](/thinking-sphinx/installing_sphinx.html)
