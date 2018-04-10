# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::Depolymorph::BaseReflection
  def initialize(reflection, name, class_name)
    @reflection = reflection
    @name       = name
    @class_name = class_name

    @options = reflection.options.clone
  end

  def call
    # Should be implemented by subclasses.
  end

  private

  attr_reader :reflection, :name, :class_name

  def klass
    reflection.class
  end

  def options
    @options.delete :polymorphic
    @options[:class_name]    = class_name
    @options[:foreign_key] ||= "#{reflection.name}_id"
    @options[:foreign_type]  = reflection.foreign_type

    @options
  end
end
