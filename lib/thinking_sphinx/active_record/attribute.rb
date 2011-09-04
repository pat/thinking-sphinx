class ThinkingSphinx::ActiveRecord::Attribute < ThinkingSphinx::Attribute
  attr_reader :source, :column

  def initialize(column, options = {})
    @column, @options = column, options
  end

  def name
    (@options[:as] || column.__name).to_s
  end

  def to_group_sql
    column.__name.to_s
  end

  def to_select_sql
    if @options[:as].present?
      "#{column.__name} AS #{@options[:as]}"
    else
      column.__name.to_s
    end
  end

  def type
    return :integer

    @type ||= begin
      base_type = case
      when is_many?, is_many_ints?
        :multi
      when @associations.values.flatten.length > 1
        :string
      else
        translated_type_from_database
      end

      if base_type == :string && @crc
        base_type = :integer
      else
        @crc = false unless base_type == :multi && is_many_strings? && @crc
      end

      base_type
    end
  end
end
