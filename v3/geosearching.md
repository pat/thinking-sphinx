---
layout: en
title: Geo-searching
gem_version: v3
---

## Geo-Searching

One of the neat features of Sphinx is the ability to sort and filter by a calculated geographical distance, from latitude and longitude values. It's quite easy to get set up, as well.

### Setting up the Indexes

Firstly, you'll need to be storing latitude and longitude values as attributes for each relevant document. So, in your index definition, you'll need something like this, if you've already got the columns in your model:

{% highlight ruby %}
has latitude, longitude
{% endhighlight %}

Keep in mind, though, that Sphinx needs these values to be **floats**, and tracking positions by **radians** instead of degrees. If this isn't the case in your own database (which isn't a surprise - most people store the values as degrees), then you'll need to manually convert columns for the attributes:

{% highlight ruby %}
has "RADIANS(latitude)",  :as => :latitude,  :type => :float
has "RADIANS(longitude)", :as => :longitude, :type => :float

# If you're using PostgreSQL:
group_by 'latitude', 'longitude'
{% endhighlight %}

Once this is done, you'll need to rebuild your Sphinx indexes:

{% highlight sh %}
rake ts:rebuild
{% endhighlight %}

You can name your attributes to be whatever you like - Thinking Sphinx will automatically use them if they're called latitude, longitude, lat or lng.

### Searching

Once your indexes are set up, then you can begin searching. You need to make sure you're doing two things:

* Provide a geographical reference point
* Filter or sort by the calculated distance

For the first, you can provide an array of two arguments (latitude and longitude, again in *radians*) to the `:geo` option. For the second, you'll need to refer to Sphinx's generated attribute `geodist` in a filter and/or a sort argument.

{% highlight ruby %}
# Searching for places within 10km
Place.search "pancakes", :geo => [@lat, @lng],
  :with => {:geodist => 0.0..10_000.0}
# Searching for places sorted by closest first
Place.search "pancakes", :geo => [@lat, @lng],
  :order => "geodist ASC, @relevance DESC"
{% endhighlight %}

If you do not provide any reference to `geodist`, then the lat/lng values will be ignored by Sphinx.

<div class="note">
  <p><strong>Note</strong>: Sphinx expects the latitude and longitude values to be in radians - so you will probably need to convert the values when searching.</p>
</div>

<div class="note">
  <p class="old">Thinking Sphinx v1/v2</p>
  <p><strong>Note</strong>: If you are using an older version of Thinking Sphinx, then the generated geodist attribute needs to be referenced with an @ prefix:</p>

  {% highlight ruby %}
# Searching for places within 10km
Place.search "pancakes", :geo => [@lat, @lng],
  :with => {'@geodist' => 0.0..10_000.0}
# Searching for places sorted by closest first
Place.search "pancakes", :geo => [@lat, @lng],
  :order => "@geodist ASC, @relevance DESC"
{% endhighlight %}
</div>

### Displaying Results

#### Thinking Sphinx since 3.0.0

When you provide a `:geo` option to your search, the distance pane is automatically added to search results, and so you can access the calculated Sphinx distance through either the `distance` or `geodist` methods (your model's own methods of those names take precedence if they exist):

{% highlight erb %}
<% @places.each do |place| %>
  <li><%= place.name %>, <%= place.distance %></li>
<% end %>
{% endhighlight %}

It's worth noting that the distance is in metres - so those stuck on the Imperial system (Americans, that's you), you might want to convert to less archaic measurements.

#### Thinking Sphinx before 3.0.0

There's two ways to access the calculated distance. You can either enumerate through the collection using `each_with_geodist`:

{% highlight erb %}
<% @places.each_with_geodist do |place, distance| %>
  <li><%= place.name %>, <%= distance %></li>
<% end %>
{% endhighlight %}

Or, you can access the distance as part of the @sphinx_attributes@ collection:

{% highlight rhtml %}
<% @places.each do |place| %>
  <li>
    <%= place.name %>,
    <%= place.sphinx_attributes['@geodist'] %>
  </li>
<% end %>
{% endhighlight %}
