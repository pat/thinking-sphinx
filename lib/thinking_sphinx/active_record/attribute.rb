class ThinkingSphinx::ActiveRecord::Attribute <
  ThinkingSphinx::ActiveRecord::Property

  delegate :type, :type=, :multi?, :updateable?, :to => :typist
  delegate :value_for,                           :to => :values

  private

  def typist
    @typist ||= ThinkingSphinx::ActiveRecord::AttributeType.new self, @model
  end

  def values
    @values ||= ThinkingSphinx::ActiveRecord::Attribute::Values.new self
  end
end

require 'thinking_sphinx/active_record/attribute_values'
