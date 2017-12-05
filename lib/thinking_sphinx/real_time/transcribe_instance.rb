class ThinkingSphinx::RealTime::TranscribeInstance
  def self.call(instance, index, properties)
    new(instance, index, properties).call
  end

  def initialize(instance, index, properties)
    @instance, @index, @properties = instance, index, properties
  end

  def call
    properties.each_with_object([document_id]) do |property, instance_values|
      instance_values << property.translate(instance)
    end
  end

  private

  attr_reader :instance, :index, :properties

  def document_id
    index.document_id_for_key instance.id
  end
end
