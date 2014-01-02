class ThinkingSphinx::IndexSet
  include Enumerable

  delegate :each, :empty?, :to => :indices

  def initialize(classes, index_names, configuration = nil)
    @classes       = classes || []
    @index_names   = index_names
    @configuration = configuration || ThinkingSphinx::Configuration.instance
  end

  def ancestors
    classes_and_ancestors - classes
  end

  def to_a
    indices
  end

  private

  def classes_and_ancestors
    @classes_and_ancestors ||= @classes.collect { |model|
      model.ancestors.take_while { |klass|
        klass != ActiveRecord::Base
      }.select { |klass|
        klass.class == Class
      }
    }.flatten
  end

  def indices
    @configuration.preload_indices

    return @configuration.indices.select { |index|
      @index_names.include?(index.name)
    } if @index_names && @index_names.any?

    return @configuration.indices if @classes.empty?

    @configuration.indices_for_references(*references)
  end

  def references
    classes_and_ancestors.collect { |klass|
      klass.name.underscore.to_sym
    }
  end
end
