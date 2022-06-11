# frozen_string_literal: true

class ThinkingSphinx::Processor
  def initialize(instance: nil, model: nil, id: nil)
    raise ArgumentError if instance.nil? && (model.nil? || id.nil?)

    @instance = instance
    @model = model || instance.class
    @id = id
  end

  def delete
    return if instance&.new_record?

    indices.each { |index|
      ThinkingSphinx::Deletion.perform(
        index, id || instance.public_send(index.primary_key)
      )
    }
  end

  def upsert
    real_time_indices.each do |index|
      ThinkingSphinx::RealTime::Transcriber.new(index).copy loaded_instance
    end
  end

  private

  attr_reader :instance, :model, :id

  def indices
    ThinkingSphinx::Configuration.instance.index_set_class.new(
      :instances => [instance].compact, :classes => [model]
    ).to_a
  end

  def loaded_instance
    @loaded_instance ||= instance || model.find(id)
  end

  def real_time_indices
    indices.select { |index| index.is_a? ThinkingSphinx::RealTime::Index }
  end
end
