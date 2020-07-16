---
layout: en
title:  Installing Sphinx on MacOS X
gem_version: v5
redirect_from: "/installing_sphinx/mac.html"
---

## Installing Sphinx on MacOS X

Both Homebrew and MacPorts are lagging in their support of Sphinx - the latest version available in both is v2.2.11, which does not work well with recent (v8) releases of MySQL.

In Homebrew's case, they also have stopped supporting the PostgreSQL option (which is essential if you're using SQL-backed indices and a PostgreSQL database).

The recommended options are instead:

* [download a pre-built set of binaries](http://sphinxsearch.com/downloads/current/) and copy the appropriate files from the supplied `bin` directory into `/usr/local/bin` (but don't replace the entire directory!); or…
* [compile Sphinx by hand](../installing_sphinx.html#compiling-sphinx-manually)

Compiling will require the MacOS Developer Tools, but it should install the files into their appropriate locations.

[Return to [Installing Sphinx]](/thinking-sphinx/installing_sphinx.html)
