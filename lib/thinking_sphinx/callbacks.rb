class ThinkingSphinx::Callbacks
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
