class ThinkingSphinx::Index
  def self.define(reference, options = {}, &block)
    unless options[:delta]
      define_single_index reference, options, &block
    else
      define_delta_index_pair reference, options, &block
    end
  end

  def self.define_single_index(reference, options = {}, &block)
    index_class(options).new(reference, options).tap do |index|
      index.definition_block = block
      ThinkingSphinx::Configuration.instance.indices << index
    end
  end

  def self.define_delta_index_pair(reference, options = {}, &block)
    processor = ThinkingSphinx::Deltas.processor_for options.delete(:delta)
    [false, true].collect do |delta|
      index_class(options).new(
        reference,
        options.merge(:delta? => delta, :delta_processor => processor)
      ).tap do |index|
        index.definition_block = block
        ThinkingSphinx::Configuration.instance.indices << index
      end
    end
  end

  def self.index_class(options)
    case options[:with]
    when :active_record
      ThinkingSphinx::ActiveRecord::Index
    when :real_time
      ThinkingSphinx::RealTime::Index
    else
      raise "Unknown index type: #{options[:with]}"
    end
  end
end
