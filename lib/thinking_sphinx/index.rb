class ThinkingSphinx::Index
  attr_reader :reference, :options, :block

  def self.define(reference, options = {}, &block)
    new(reference, options, &block).indices.each do |index|
      ThinkingSphinx::Configuration.instance.indices << index
    end
  end

  def initialize(reference, options, &block)
    defaults = ThinkingSphinx::Configuration.instance.
      settings['index_options'] || {}
    defaults.symbolize_keys!

    @reference, @options, @block = reference, defaults.merge(options), block
  end

  def indices
    options[:delta] ? delta_indices : [single_index]
  end

  private

  def index_class
    case options[:with]
    when :active_record
      ThinkingSphinx::ActiveRecord::Index
    when :real_time
      ThinkingSphinx::RealTime::Index
    else
      raise "Unknown index type: #{options[:with]}"
    end
  end

  def single_index
    index_class.new(reference, options).tap do |index|
      index.definition_block = block
    end
  end

  def delta_indices
    [false, true].collect do |delta|
      index_class.new(
        reference,
        options.merge(:delta? => delta, :delta_processor => processor)
      ).tap do |index|
        index.definition_block = block
      end
    end
  end

  def processor
    @processor ||= ThinkingSphinx::Deltas.processor_for options.delete(:delta)
  end
end
