class ThinkingSphinx::ActiveRecord::SQLSource < Riddle::Configuration::SQLSource
  attr_reader :model, :database_settings, :options
  
  # Options:
  # - :name
  # - :offset
  # - :delta_processor
  # - :delta?
  # - :disable_range
  # - :group_concat_max_len
  # - :utf8?
  # 
  def initialize(model, options = {})
    @model             = model
    @database_settings = model.connection.instance_variable_get(:@config).clone
    @options           = options
    
    name = "#{options[:name] || model.name.downcase}_#{name_suffix}"
    
    super name, type
  end
  
  def adapter
    @adapter ||= ThinkingSphinx::ActiveRecord::Base.adapter_for @model
  end
  
  def delta_processor
    options[:delta_processor]
  end
  
  def delta?
    options[:delta?]
  end
  
  def offset
    options[:offset]
  end
  
  def render
    prepare_for_render
    
    super
  end
  
  def type
    @type ||= case adapter
    when ThinkingSphinx::Adapters::MySQLAdapter
      'mysql'
    when ThinkingSphinx::Adapters::PostgreSQLAdapter
      'pgsql'
    else
      raise "Unknown Adapter Type: #{adapter.class.name}"
    end
  end
  
  private
  
  def name_suffix
    delta? ? 'delta' : 'core'
  end
  
  def prepare_for_render
    @sql_host ||= database_settings[:host]     || 'localhost'
    @sql_user ||= database_settings[:username] || database_settings[:user]
    @sql_pass ||= database_settings[:password].to_s.gsub('#', '\#')
    @sql_db   ||= database_settings[:database]
    @sql_port ||= database_settings[:port]
    @sql_sock ||= database_settings[:socket]
    
    # fields
    # attributes
    
    # config.options.each do |key, value|
    #   next unless self.respond_to?("#{key}=") && self.send(key).nil?
    #   self.send("#{key}=", value)
    # end
    
    @sql_query       = builder.sql_query
    @sql_query_range = builder.sql_query_range
    @sql_query_info  = builder.sql_query_info
    @sql_query_pre  += builder.sql_query_pre
  end
  
  def builder
    @builder ||= ThinkingSphinx::ActiveRecord::SQLBuilder.new self
  end
end
