# frozen_string_literal: true

class ThinkingSphinx::Callbacks
  attr_reader :instance

  def self.append(model, reference = nil, options, &block)
    reference ||= ThinkingSphinx::Configuration.instance.index_set_class.
      reference_name(model)

    ThinkingSphinx::Callbacks::Appender.call(model, reference, options, &block)
  end

  def self.callbacks(*methods)
    mod = Module.new
    methods.each do |method|
      mod.send(:define_method, method) { |instance| new(instance).send(method) }
    end
    extend mod
  end

  def self.resume!
    @suspended = false
  end

  def self.suspend(&block)
    suspend!
    yield
    resume!
  end

  def self.suspend!
    @suspended = true
  end

  def self.suspended?
    @suspended
  end

  def initialize(instance)
    @instance = instance
  end
end

require "thinking_sphinx/callbacks/appender"
