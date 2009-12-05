class ThinkingSphinx::DataMapper::Tailor
  attr_accessor :model, :base
  
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
    @model.repository.adapter.send :quote_name, column.to_s
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
  
  def columns
    @model.properties
  end
  
  def columns_for(klass)
    klass.properties
  end
  
  def column_type(column)
    case column.type
    when DataMapper::Types::Serial,
         DataMapper::Types::Integer
      :integer
    when DataMapper::Types::String
      :string
    when DataMapper::Types::Text
      :text
    when DataMapper::Types::Boolean
      :boolean
    when DataMapper::Types::Float
      :float
    when DataMapper::Types::DateTime
      :datetime
    when DataMapper::Types::Date
      :date
    when DataMapper::Types::Time
      :time
    else
      :string
    end
  end
  
  # Checks to see if MySQL will allow simplistic GROUP BY statements. If not,
  # or if not using MySQL, this will return false.
  #
  def use_group_by_shortcut?
    !!(
      mysql? && @model.repository.adapter.query(
        "SELECT @@global.sql_mode, @@session.sql_mode;"
      ).first.all? { |value| value.nil? || value[/ONLY_FULL_GROUP_BY/].nil? }
    )
  end
  
  private
  
  def adapter
    @model.sphinx_database_adapter
  end
  
  def mysql?
    adapter.sphinx_identifier == 'mysql'
  end
end
