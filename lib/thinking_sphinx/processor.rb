# frozen_string_literal: true

class ThinkingSphinx::Processor
  def initialize(instance)
    @instance = instance
  end

  def delete
    return if instance.new_record?

    indices.each { |index|
      ThinkingSphinx::Deletion.perform(
        index, instance.public_send(index.primary_key)
      )
    }
  end

  def upsert
    real_time_indices.each do |index|
      ThinkingSphinx::RealTime::Transcriber.new(index).copy instance
    end
  end

  private

  attr_reader :instance

  def indices
    ThinkingSphinx::Configuration.instance.index_set_class.new(
      :instances => [instance], :classes => [instance.class]
    ).to_a
  end

  def real_time_indices
    indices.select { |index| index.is_a? ThinkingSphinx::RealTime::Index }
  end
end
