# frozen_string_literal: true

class ThinkingSphinx::IndexSet
  include Enumerable

  def self.reference_name(klass)
    @cached_results ||= {}
    @cached_results[klass.name] ||= klass.name.underscore.to_sym
  end

  delegate :each, :empty?, :to => :indices

  def initialize(options = {}, configuration = nil)
    @options       = options
    @index_names   = options[:indices] || []
    @configuration = configuration || ThinkingSphinx::Configuration.instance
  end

  def ancestors
    classes_and_ancestors - classes
  end

  def to_a
    indices
  end

  private

  attr_reader :configuration, :options

  def all_indices
    configuration.preload_indices
    configuration.indices
  end

  def classes
    options[:classes] || instances.collect(&:class)
  end

  def classes_specified?
    instances.any? || classes.any? || references_specified?
  end

  def classes_and_ancestors
    @classes_and_ancestors ||= mti_classes + sti_classes.collect { |model|
      model.ancestors.take_while { |klass|
        klass != ActiveRecord::Base
      }.select { |klass|
        klass.class == Class
      }
    }.flatten
  end

  def index_names
    options[:indices] || []
  end

  def indices
    return all_indices.select { |index|
      index_names.include?(index.name)
    } if index_names.any?

    everything = classes_specified? ? indices_for_references : all_indices
    everything.reject &:distributed?
  end

  def indices_for_references
    all_indices.select { |index| references.include? index.reference }
  end

  def instances
    options[:instances] || []
  end

  def mti_classes
    classes.reject { |klass|
      klass.column_names.include?(klass.inheritance_column)
    }
  end

  def references
    options[:references] || classes_and_ancestors.collect { |klass|
      ThinkingSphinx::IndexSet.reference_name(klass)
    }
  end

  def references_specified?
    options[:references] && options[:references].any?
  end

  def sti_classes
    classes.select { |klass|
      klass.column_names.include?(klass.inheritance_column)
    }
  end
end
