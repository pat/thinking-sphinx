require 'active_support/core_ext/module/delegation'

class ThinkingSphinx::Middlewares::Geographer <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each do |context|
      Inner.new(context).call
    end

    app.call contexts
  end

  private

  class Inner
    def initialize(context)
      @context = context
    end

    def call
      return unless geo

      context[:sphinxql].values geodist_clause
      context[:panes] << ThinkingSphinx::Panes::DistancePane
    end

    private

    attr_reader :context

    delegate :geo, :latitude, :longitude, :to => :geolocation_attributes

    def geolocation_attributes
      @geolocation_attributes ||= GeolocationAttributes.new(context)
    end

    def geodist_clause
      "GEODIST(#{geo.first}, #{geo.last}, #{latitude}, #{longitude}) AS geodist"
    end

    class GeolocationAttributes
      def initialize(context)
        self.context = context
        self.latitude = latitude_attr if latitude_attr
        self.longitude = longitude_attr if longitude_attr
      end

      def geo
        search_context_options[:geo]
      end
      attr_accessor :latitude, :longitude

      def latitude
        @latitude ||= names.detect { |name| %w[lat latitude].include?(name) } || 'lat'
      end

      def longitude
        @longitude ||= names.detect { |name| %w[lng longitude].include?(name) } || 'lng'
      end

      private
      attr_accessor :context

      def latitude_attr
        @latitude_attr ||= search_context_options[:latitude_attr]
      end

      def longitude_attr
        @longitude_attr ||= search_context_options[:longitude_attr]
      end

      def indices
        context[:indices]
      end

      def names
        @names ||= indices.collect(&:unique_attribute_names).flatten.uniq
      end

      def search_context_options
        @search_context_options ||= context.search.options
      end
    end
  end
end
