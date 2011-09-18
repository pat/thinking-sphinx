class ThinkingSphinx::ActiveRecord::Attribute <
  ThinkingSphinx::ActiveRecord::Property

  def type_for(model)
    @options[:type] || type_from_database_for(model)

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

  def type_from_database_for(model)
    db_type = model.columns.detect { |db_column|
      db_column.name == columns.first.__name.to_s
    }.type

    case db_type
    when :datetime
      :timestamp
    else
      db_type
    end
  end
end
