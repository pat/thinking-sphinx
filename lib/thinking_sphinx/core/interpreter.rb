# frozen_string_literal: true

class ThinkingSphinx::Core::Interpreter < BasicObject
  def self.translate!(index, block)
    new(index, block).translate!
  end

  def initialize(index, block)
    @index = index

    mod = ::Module.new
    mod.send :define_method, :translate!, block
    mod.send :extend_object, self
  end

  private

  def search_option?(key)
    ::ThinkingSphinx::Middlewares::SphinxQL::SELECT_OPTIONS.include? key
  end

  def method_missing(method, *args)
    ::ThinkingSphinx::ActiveRecord::Column.new method, *args
  end
end
