class ThinkingSphinx::Core::Interpreter < BlankSlate
  def self.reveal(name)
    hidden_method = find_hidden_method(name)
    fail "Don't know how to reveal method '#{name}'" unless hidden_method
    define_method(name, hidden_method)
  end

  reveal :extend if RUBY_DESCRIPTION[/^ruby 1.9/].nil?

  def self.translate!(index, block)
    new(index, block).translate!
  end

  def initialize(index, block)
    @index = index

    mod = Module.new
    mod.send :define_method, :translate!, block
    extend mod
  end

  private

  def method_missing(method, *args)
    ThinkingSphinx::ActiveRecord::Column.new method, *args
  end
end
