class ThinkingSphinx::ActiveRecord::Attribute <
  ThinkingSphinx::ActiveRecord::Property

  delegate :type, :type=, :multi?, :updateable?, :to => :typist
  delegate :value_for,                           :to => :values

  def source_type
    options[:source]
  end

  private

  def typist
    @typist ||= ThinkingSphinx::ActiveRecord::Attribute::Type.new self, @model
  end

  def values
    @values ||= ThinkingSphinx::ActiveRecord::Attribute::Values.new self
  end
end

require 'thinking_sphinx/active_record/attribute/query'
require 'thinking_sphinx/active_record/attribute/sphinx_presenter'
require 'thinking_sphinx/active_record/attribute/type'
require 'thinking_sphinx/active_record/attribute/values'
