class ThinkingSphinx::ActiveRecord::SQLSource < Riddle::Configuration::SQLSource
  attr_reader :model, :database_settings, :options, :conditions, :groupings
  attr_accessor :fields, :attributes, :associations

  def self.internal_attributes(model)
    [
      ThinkingSphinx::ActiveRecord::Attribute.new(
        ThinkingSphinx::ActiveRecord::Column.new(:id),
        :as => :sphinx_internal_id,    :type => :integer
      ),
      ThinkingSphinx::ActiveRecord::Attribute.new(
        ThinkingSphinx::ActiveRecord::Column.new("'#{model.name}'"),
        :as => :sphinx_internal_class, :type => :string
      )
    ]
  end

  # Options:
  # - :name
  # - :offset
  # - :delta_processor
  # - :delta?
  # - :disable_range?
  # - :group_concat_max_len
  # - :utf8?
  #
  def initialize(model, options = {})
    @model             = model
    @database_settings = model.connection.instance_variable_get(:@config).clone
    @options           = options

    @fields            = []
    @attributes        = self.class.internal_attributes(model)
    @associations      = []
    @conditions        = []
    @groupings         = []

    name = "#{options[:name] || model.name.downcase}_#{name_suffix}"

    super name, type
  end

  def adapter
    @adapter ||= ThinkingSphinx::ActiveRecord::DatabaseAdapters.
      adapter_for(@model)
  end

  def delta_processor
    options[:delta_processor]
  end

  def delta?
    options[:delta?]
  end

  def disable_range?
    options[:disable_range?]
  end

  def offset
    options[:offset]
  end

  def render
    self.class.settings.each do |setting|
      value = config.settings[setting.to_s]
      send("#{setting}=", value) unless value.nil?
    end

    prepare_for_render unless @prepared

    super
  end

  def type
    @type ||= case adapter
    when ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter
      'mysql'
    when ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter
      'pgsql'
    else
      raise "Unknown Adapter Type: #{adapter.class.name}"
    end
  end

  private

  def builder
    @builder ||= ThinkingSphinx::ActiveRecord::SQLBuilder.new self
  end

  def config
    ThinkingSphinx::Configuration.instance
  end

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
    fields.each do |field|
      @sql_field_string << field.name if field.with_attribute?
    end

    # attributes
    attributes.each do |attribute|
      case attribute.type_for(model)
      when :integer
        @sql_attr_uint << attribute.name
      when :boolean
        @sql_attr_bool << attribute.name
      when :string
        @sql_attr_string << attribute.name
      when :timestamp
        @sql_attr_timestamp << attribute.name
      when :float
        @sql_attr_float << attribute.name
      else
        raise "Unknown attribute type '#{attribute.type_for(model)}'"
      end
    end

    @sql_query       = builder.sql_query
    @sql_query_range = builder.sql_query_range
    @sql_query_info  = builder.sql_query_info
    @sql_query_pre  += builder.sql_query_pre

    @prepared = true
  end
end
