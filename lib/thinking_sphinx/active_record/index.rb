class ThinkingSphinx::ActiveRecord::Index < Riddle::Configuration::Index
  attr_reader :reference
  attr_writer :definition_block

  def initialize(reference)
    @reference = reference

    super reference.to_s
  end

  def interpret_definition!
    return if @interpreted_definition

    ThinkingSphinx::ActiveRecord::Interpreter.translate! self, @definition_block
    @interpreted_definition = true
  end

  def render
    interpret_definition!

    super
  end
end
