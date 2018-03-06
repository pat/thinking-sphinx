---
layout: en
title: Contributing to Thinking Sphinx
gem_version: v4
---

## Contributing to Thinking Sphinx

* [Forking and Patching](#forking)
* [Dependencies](#dependencies)

<h3 id="forking">Forking and Patching</h3>

If you're offering a patch to Thinking Sphinx, the best way to do this is to fork [the GitHub project](http://github.com/pat/thinking-sphinx), write a patch in a new branch, and then send me a Pull Request. This last step is important - while I may be following your fork on GitHub, the request means an email ends up in my inbox, so I won't forget about your changes.

Do not forget to add specs. This keeps Thinking Sphinx as stable as possible, and makes it far easier for me to merge your changes in.

Sometimes I accept patches, sometimes I don't. Please don't be offended if your patch falls into the latter category - I want to keep Thinking Sphinx as lean as possible, and that means I don't add every feature that people request or write.

If you have a contribution in mind but want some feedback, just create an issue on GitHub and I'll be happy to discuss it further with you.

<h3 id="dependencies">Dependencies</h3>

Just use `bundle install` to get development dependencies installed. The acceptance tests run on MySQL by default, but you can switch to PostgreSQL using the `DATABASE` environment variable:

{% highlight sh %}
DATABASE=postgresql rspec spec
{% endhighlight %}

MySQL's expected user is root, and PostgreSQL's expected user is your local user. Running tests against both databases is recommended.

Sphinx 2.0.6 or newer is required for Thinking Sphinx v3, so make sure you have that.
