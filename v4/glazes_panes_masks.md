---
layout: en
title: Search Glazes, Panes, and Masks
gem_version: v4
disable_versions: true
redirect_from: "/glazes_panes_masks.html"
---

## Search Glazes, Panes, and Masks

### Glazes and Panes

Sometimes it’s useful to have pieces of metadata associated with each search result.

Instead of monkey-patching ActiveRecord instances that are returned in search results, Thinking Sphinx chooses to wrap these objects within a presenter object (a _glaze_). A glaze can then have different `panes` that provide helper methods - though methods that exist on the model instances themselves are prioritised.

By default, no panes or glazes are used in search requests - but they can be used if you wish. The following panes are currently available within Thinking Sphinx itself:

* `ThinkingSphinx::Panes::AttributesPane` provides a method called `sphinx_attributes` which is a hash of the raw Sphinx attribute values. This is useful when your Sphinx attributes hold complex values that you don’t want to re-calcuate.
* `ThinkingSphinx::Panes::DistancePane` provides the identical distance and geodist methods returning the calculated distance between lat/lng geographical points (and is added automatically if the :geo option is present).
* `ThinkingSphinx::Panes::ExcerptsPane` provides access to an excerpts method which you can then chain any call to a method on the search result - and get an excerpted value returned.
* `ThinkingSphinx::Panes::WeightPane` provides the weight method, returning Sphinx’s calculated relevance score.

You can add specific panes like so:

{% highlight ruby %}
# For every search
ThinkingSphinx::Configuration::Defaults::PANES <<
  ThinkingSphinx::Panes::WeightPane

# Or for specific searches:
search = ThinkingSphinx.search('pancakes')
search.context[:panes] << ThinkingSphinx::Panes::WeightPane
{% endhighlight %}

When you do add at least one pane into the mix, the search result gets wrapped in a glaze object. These glaze objects direct any methods called upon themselves with the following logic:

* If the search result responds to the given method, send it to that search result.
* Else if any pane responds to the given method, send it to the pane.
* Otherwise, send it to the search result anyway.

This means that your ActiveRecord instances take priority – so pane methods don’t overwrite your own code. It also allows for method_missing metaprogramming in your models (and ActiveRecord itself) – but otherwise, you can get access to the useful metadata Sphinx can provide, without monkeypatching objects on the fly.

If you’re writing your own panes, the only requirement is that the initializer must accept three arguments: the search context, the underlying search result object, and a hash of the raw values from Sphinx. The source code for the panes is not overly complex - so have a [read through that](https://github.com/pat/thinking-sphinx/tree/develop/lib/thinking_sphinx/panes) for inspiration.

### Search Masks

Perhaps the terminology is a little overdone, but Masks provide similar functionality to Glazes/Panes, though for the overall search result collection rather than per-result. That is: they provide helper methods on top of the search result collection.

The provided masks are:

* `ThinkingSphinx::Masks::PaginationMask` which provides pagination-related methods (as expected by Kaminari and WillPaginate).
* `ThinkingSphinx::Masks::ScopesMask` which allows chaining of scopes upon an existing search result set.
* `ThinkingSphinx::Masks::GroupEnumeratorsMask` which supplies methods related to grouped search results: `each_with_count`, `each_with_group`, and `each_with_group_and_count`.

Should you wish to create your own mask, they must be classes that accept a search result collection as the only initializer parameter, and have a `can_handle?` method, which indicates whether the given argument is an available method in the mask. The source code for [the `GroupEnumeratorsMask`](https://github.com/pat/thinking-sphinx/blob/develop/lib/thinking_sphinx/masks/group_enumerators_mask.rb) is a good reference.

You can add specific masks like so:

{% highlight ruby %}
# For every search
ThinkingSphinx::Search::DEFAULT_MASKS << MyMask

# Or for specific searches:
Article.search(
  'pancakes',
  :masks => (ThinkingSphinx::Search::DEFAULT_MASKS + [MyMask])
)
{% endhighlight %}

These masks _must_ be added before search results are populated (so)
