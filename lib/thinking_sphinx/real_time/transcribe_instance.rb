class ThinkingSphinx::RealTime::TranscribeInstance
  def self.call(instance, index, properties)
    new(instance, index, properties).call
  end

  def initialize(instance, index, properties)
    @instance, @index, @properties = instance, index, properties
  end

  def call
    properties.each_with_object([document_id]) do |property, instance_values|
      begin
        instance_values << property.translate(instance)
      rescue StandardError => error
        raise_wrapper error, property
      end
    end
  end

  private

  attr_reader :instance, :index, :properties

  def document_id
    index.document_id_for_key instance.id
  end

  def raise_wrapper(error, property)
    wrapper = ThinkingSphinx::TranscriptionError.new
    wrapper.inner_exception = error
    wrapper.instance        = instance
    wrapper.property        = property

    raise wrapper
  end
end
