class ThinkingSphinx::ActiveRecord::Attribute::Type
  UPDATEABLE_TYPES = [:integer, :timestamp, :boolean, :float]

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

  def type=(value)
    @type = attribute.options[:type] = value
  end

  def updateable?
    UPDATEABLE_TYPES.include?(type) && single_column_reference?
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

  def big_integer?
    database_column.type == :integer && database_column.sql_type[/bigint/i]
  end

  def column_name
    attribute.columns.first.__name.to_s
  end

  def database_column
    @database_column ||= klass.columns.detect { |db_column|
      db_column.name == column_name
    }
  end

  def klass
    @klass ||= associations.any? ? associations.last.klass : model
  end

  def multi_from_associations
    associations.any? { |association|
      [:has_many, :has_and_belongs_to_many].include?(association.macro)
    }
  end

  def single_column_reference?
    attribute.columns.length == 1               &&
    attribute.columns.first.__stack.length == 0 &&
    !attribute.columns.first.string?
  end

  def type_from_database
    raise ThinkingSphinx::MissingColumnError,
      "Cannot determine the database type of column #{column_name}, as it does not exist" if database_column.nil?

    return :bigint if big_integer?

    case database_column.type
    when :datetime, :date
      :timestamp
    when :text
      :string
    when :decimal
      :float
    else
      database_column.type
    end
  end
end
