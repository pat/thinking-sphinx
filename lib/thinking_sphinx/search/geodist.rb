module ThinkingSphinx::Search::Geodist
  def self.included(base)
    base.instance_eval do
      alias_method :sphinxql_select_without_geo, :sphinxql_select
      alias_method :sphinxql_select, :sphinxql_select_with_geo
    end
  end

  private

  def geo
    options[:geo]
  end

  def geodist_clause
    "GEODIST(#{geo.first}, #{geo.last}, #{latitude_attribute}, #{longitude_attribute}) AS geodist"
  end

  def latitude_attribute
    @search.options[:latitude_attr] || 'lat'
  end

  def longitude_attribute
    @search.options[:longitude_attr] || 'lng'
  end

  def sphinxql_select_with_geo
    sphinxql_select_without_geo.tap do |select|
      select.values geodist_clause if geo
    end
  end
end
