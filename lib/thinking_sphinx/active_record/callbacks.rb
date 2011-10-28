class ThinkingSphinx::ActiveRecord::Callbacks
  attr_reader :instance

  def self.callbacks(*methods)
    mod = Module.new
    methods.each do |method|
      mod.send(:define_method, method) { |instance| new(instance).send(method) }
    end
    extend mod
  end

  def initialize(instance)
    @instance = instance
  end
end

require 'thinking_sphinx/active_record/callbacks/delete_callbacks'
require 'thinking_sphinx/active_record/callbacks/delta_callbacks'
