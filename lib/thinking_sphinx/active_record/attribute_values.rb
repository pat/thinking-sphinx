class ThinkingSphinx::ActiveRecord::Attribute::Values
  def initialize(attribute)
    @attribute = attribute
  end

  def value_for(instance)
    object = column.__stack.inject(instance) { |object, name|
      object.nil? ? nil : object.send(name)
    }
    object.nil? ? nil : object.send(column.__name)
  end

  private

  def column
    @attribute.columns.first
  end
end
