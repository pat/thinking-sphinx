# frozen_string_literal: true

class ThinkingSphinx::Distributed::Index <
  Riddle::Configuration::DistributedIndex

  attr_reader :reference, :options, :local_index_objects

  def initialize(reference)
    @reference           = reference
    @options             = {}
    @local_index_objects = []

    super reference.to_s.gsub('/', '_')
  end

  def delta?
    false
  end

  def distributed?
    true
  end

  def facets
    local_index_objects.collect(&:facets).flatten
  end

  def local_index_objects=(indices)
    self.local_indices = indices.collect(&:name)
    @local_index_objects = indices
  end

  def model
    @model ||= reference.to_s.camelize.constantize
  end

  def primary_key
    @primary_key ||= configuration.settings['primary_key'] || :id
  end

  private

  def configuration
    ThinkingSphinx::Configuration.instance
  end
end
