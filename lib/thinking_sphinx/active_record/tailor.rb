class ThinkingSphinx::ActiveRecord::Tailor
  attr_reader :model, :base
  
  def initialize(source)
    @model = source.model
    
    @base = ::ActiveRecord::Associations::ClassMethods::JoinDependency.new(
      @model, [], nil
    )
    
    unless @model.descends_from_active_record?
      stored_class = @model.store_full_sti_class ? @model.name : @model.name.demodulize
      source.conditions << "#{@model.quoted_table_name}.#{quote_column_name(@model.inheritance_column)} = '#{stored_class}'"
    end
  end
  
  def database_settings
    @model.connection.instance_variable_get(:@config)
  end
  
  def quoted_table_name
    @model.quoted_table_name
  end
  
  def quote_column_name(column)
    @model.connection.quote_column_name(column)
  end
  
  def primary_key_for_sphinx
    @model.primary_key_for_sphinx
  end
  
  def inherited?
    @model.column_names.include?(@model.inheritance_column)
  end
  
  def inheritance_column
    @model.inheritance_column
  end
  
  def crc_column
    if @model.table_exists? &&
      @model.column_names.include?(@model.inheritance_column)
      
      adapter.cast_to_unsigned(adapter.convert_nulls(
        adapter.crc(adapter.quote_with_table(@model.inheritance_column), true),
        @model.to_crc32
      ))
    else
      @model.to_crc32.to_s
    end
  end
  
  private
  
  def adapter
    @model.sphinx_database_adapter
  end
end
