module ThinkingSphinx::ActiveRecord::AssociationProxy
  extend ActiveSupport::Concern

  def search(query = nil, options = {})
    ThinkingSphinx::Search::Merger.new(super).merge! nil,
      :with => association_filter
  end

  def search_for_ids(query = nil, options = {})
    ThinkingSphinx::Search::Merger.new(super).merge! nil,
      :with => association_filter
  end

  private

  def association_filter
    attribute = AttributeFinder.new(proxy_association).attribute

    {attribute.name.to_sym => proxy_association.owner.id}
  end

  class AttributeFinder
    def initialize(association)
      @association = association
    end

    def attribute
      attributes.detect { |attribute|
        # Don't bother with attributes built from multiple columns
        next unless attribute.columns.length == 1

        attribute.columns.first.__name == foreign_key.to_sym ||
        attribute.name == foreign_key.to_s
      } or raise "Missing Attribute for Foreign Key #{foreign_key}"
    end

    private

    def attributes
      sources.collect(&:attributes).flatten
    end

    def configuration
      ThinkingSphinx::Configuration.instance
    end

    def foreign_key
      @foreign_key ||= if @association.reflection.through_reflection
        @association.reflection.through_reflection.foreign_key
      else
        @association.reflection.foreign_key
      end
    end

    def indices
      @indices ||= begin
        configuration.preload_indices
        configuration.indices_for_references(
          *@association.klass.name.underscore.to_sym
        )
      end
    end

    def sources
      indices.collect(&:sources).flatten
    end
  end
end
