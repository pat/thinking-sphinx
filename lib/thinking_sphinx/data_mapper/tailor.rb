class ThinkingSphinx::DataMapper::Tailor
  attr_reader :model, :base
  
  def initialize(source)
    @model = source.model
    
    # @base = ::ActiveRecord::Associations::ClassMethods::JoinDependency.new(
    #   @model, [], nil
    # )
    # 
    # unless @model.descends_from_active_record?
    #   stored_class = @model.store_full_sti_class ? @model.name : @model.name.demodulize
    #   source.conditions << "#{@model.quoted_table_name}.#{quote_column_name(@model.inheritance_column)} = '#{stored_class}'"
    # end
  end
  
  def database_settings
    options = @model.repository.adapter.options
    {
      :host     => options["host"],
      :database => options["path"].gsub(/^\//, ''),
      :username => options["user"],
      :password => options["password"],
      :port     => options["port"]
    }
  end
  
  def quoted_table_name
    @model.repository.adapter.send :quote_name,
      @model.storage_name(@model.repository.name)
  end
  
  def quote_column_name(column)
    @model.repository.adapter.send :quote_name, column
  end
  
  def primary_key_for_sphinx
    'id'
  end
  
  def inherited?
    false
  end
  
  def inheritance_column
    nil
  end
  
  def crc_column
    @model.to_crc32.to_s
  end
  
  private
  
  def adapter
    @model.sphinx_database_adapter
  end
end
