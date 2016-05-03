class ThinkingSphinx::Callbacks
  attr_reader :instance

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
