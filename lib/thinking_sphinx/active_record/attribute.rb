class ThinkingSphinx::ActiveRecord::Attribute <
  ThinkingSphinx::ActiveRecord::Property

  delegate :type, :multi?, :to => :typist

  private

  def typist
    @typist ||= ThinkingSphinx::ActiveRecord::AttributeType.new self, @model
  end
end
