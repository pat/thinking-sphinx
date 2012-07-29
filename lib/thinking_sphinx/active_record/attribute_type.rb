class ThinkingSphinx::ActiveRecord::AttributeType
  def initialize(attribute, model)
    @attribute, @model = attribute, model
  end

  def multi?
    @multi ||= attribute.options[:multi] || multi_from_associations
  end

  def timestamp?
    type == :timestamp
  end

  def type
    @type ||= attribute.options[:type] || type_from_database
  end

  private

  attr_reader :attribute, :model

  def associations
    @associations ||= begin
      klass = model
      attribute.columns.first.__stack.collect { |name|
        association = klass.reflect_on_association(name)
        klass       = association.klass
        association
      }
    end
  end

  def klass
    @klass ||= associations.any? ? associations.last.klass : model
  end

  def multi_from_associations
    associations.any? { |association|
      [:has_many, :has_and_belongs_to_many].include?(association.macro)
    }
  end

  def type_from_database
    db_type = klass.columns.detect { |db_column|
      db_column.name == attribute.columns.first.__name.to_s
    }.type

    case db_type
    when :datetime, :date
      :timestamp
    when :text
      :string
    when :decimal
      :float
    else
      db_type
    end
  end
end