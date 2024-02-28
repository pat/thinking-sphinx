# frozen_string_literal: true

class ThinkingSphinx::Processor
  # @param instance [ActiveRecord::Base] an ActiveRecord object
  # @param model [Class] the ActiveRecord model of the instance
  # @param id [Integer] the instance indices primary key (might be different from model primary key)
  def initialize(instance: nil, model: nil, id: nil)
    raise ArgumentError if instance.nil? && (model.nil? || id.nil?)

    @instance = instance
    @model = model || instance.class
    @id = id
  end

  def delete
    return if instance&.new_record?

    indices.each { |index| perform_deletion(index) }
  end

  # Will insert instance into all matching indices
  def upsert
    real_time_indices.each do |index|
      found = loaded_instance(index)
      ThinkingSphinx::RealTime::Transcriber.new(index).copy found if found
    end
  end

  # Will upsert or delete instance into all matching indices based on index scope
  def stage
    real_time_indices.each do |index|
      found = find_in(index)

      if found
        ThinkingSphinx::RealTime::Transcriber.new(index).copy found
      else
        ThinkingSphinx::Deletion.perform(index, index_id(index))
      end
    end
  end

  private

  attr_reader :instance, :model, :id

  def indices
    ThinkingSphinx::Configuration.instance.index_set_class.new(
      :instances => [instance].compact, :classes => [model]
    ).to_a
  end

  def find_in(index)
    index.scope.find_by(index.primary_key => index_id(index))
  end

  def loaded_instance(index)
    instance || find_in(index)
  end

  def real_time_indices
    indices.select { |index| index.is_a? ThinkingSphinx::RealTime::Index }
  end

  def perform_deletion(index)
    ThinkingSphinx::Deletion.perform(index, index_id(index))
  end

  def index_id(index)
    id || instance.public_send(index.primary_key)
  end
end
