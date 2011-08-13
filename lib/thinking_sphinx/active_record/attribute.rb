class ThinkingSphinx::ActiveRecord::Attribute < ThinkingSphinx::Attribute
  attr_reader :source
  
  def type
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
