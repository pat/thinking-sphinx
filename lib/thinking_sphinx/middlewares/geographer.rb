class ThinkingSphinx::Middlewares::Geographer <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each do |context|
      Inner.new(context).call
    end

    app.call contexts
  end

  class Inner
    def initialize(context)
      @context = context
    end

    def call
      context[:sphinxql].values geodist_clause if geo
    end

    private

    attr_reader :context

    def attribute_names
      @attribute_names ||= context[:indices].collect(&:unique_attribute_names).
        flatten.uniq
    end

    def geo
      context.search.options[:geo]
    end

    def geodist_clause
      "GEODIST(#{geo.first}, #{geo.last}, #{latitude_attribute}, #{longitude_attribute}) AS geodist"
    end

    def latitude_attribute
      context.search.options[:latitude_attr]                         ||
      attribute_names.detect { |attribute| attribute == 'lat' }      ||
      attribute_names.detect { |attribute| attribute == 'latitude' } || 'lat'
    end

    def longitude_attribute
      context.search.options[:longitude_attr]                         ||
      attribute_names.detect { |attribute| attribute == 'lng' }       ||
      attribute_names.detect { |attribute| attribute == 'longitude' } || 'lng'
    end
  end
end
