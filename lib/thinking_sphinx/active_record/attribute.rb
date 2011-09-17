class ThinkingSphinx::ActiveRecord::Attribute < ThinkingSphinx::Attribute
  attr_reader :source, :column

  def initialize(column, options = {})
    @column, @options = column, options
  end

  def name
    (@options[:as] || column.__name).to_s
  end

  def to_group_sql(associations)
    column.string? ? nil : column_with_table(associations)
  end

  def to_select_sql(associations)
    if @options[:as].present?
      "#{column_with_table(associations)} AS #{@options[:as]}"
    else
      column_with_table associations
    end
  end

  def type_for(model)
    @options[:type] || model.columns.detect { |db_column|
      db_column.name == column.__name.to_s
    }.type

    # @type ||= begin
    #   base_type = case
    #   when is_many?, is_many_ints?
    #     :multi
    #   when @associations.values.flatten.length > 1
    #     :string
    #   else
    #     translated_type_from_database
    #   end
    #
    #   if base_type == :string && @crc
    #     base_type = :integer
    #   else
    #     @crc = false unless base_type == :multi && is_many_strings? && @crc
    #   end
    #
    #   base_type
    # end
  end

  private

  def column_with_table(associations)
    return column.__name if column.string?

    "#{associations.alias_for(column.__stack)}.#{column.__name}"
  end
end
