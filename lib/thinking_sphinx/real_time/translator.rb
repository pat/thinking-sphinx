# frozen_string_literal: true

class ThinkingSphinx::RealTime::Translator
  def self.call(object, column)
    new(object, column).call
  end

  def initialize(object, column)
    @object, @column = object, column
  end

  def call
    return name.call(object) if name.is_a?(Proc)
    return name   unless name.is_a?(Symbol)
    return result unless result.is_a?(String)

    result.gsub("\u0000", '').force_encoding "UTF-8"
  end

  private

  attr_reader :object, :column

  def name
    @column.__name
  end

  def owner
    stack.inject(object) { |previous, node| previous.try node }
  end

  def result
    @result ||= owner.try name
  end

  def stack
    @column.__stack
  end
end
