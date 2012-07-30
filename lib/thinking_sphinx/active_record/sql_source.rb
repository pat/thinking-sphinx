class ThinkingSphinx::ActiveRecord::SQLSource < Riddle::Configuration::SQLSource
  attr_reader :model, :database_settings, :options
  attr_accessor :fields, :attributes, :associations, :conditions, :groupings

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
    @attributes        = []
    @associations      = []
    @conditions        = []
    @groupings         = []

    Template.new(self).apply

    name = "#{options[:name] || model.name.downcase}_#{name_suffix}"

    super name, type
  end

  def adapter
    @adapter ||= ThinkingSphinx::ActiveRecord::DatabaseAdapters.
      adapter_for(@model)
  end

  def delta_processor
    options[:delta_processor].try(:new, adapter)
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

  def primary_key
    options[:primary_key]
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

  def attribute_array_for(type)
    instance_variable_get "@sql_attr_#{type}".to_sym
  end

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
    set_database_settings

    fields.each do |field|
      @sql_field_string << field.name if field.with_attribute?
      @sql_file_field   << field.name if field.file?
    end

    attributes.each do |attribute|
      presenter = ThinkingSphinx::ActiveRecord::Attribute::SphinxPresenter.new(attribute)

      attribute_array_for(presenter.collection_type) << presenter.declaration
    end

    @sql_query       = builder.sql_query
    @sql_query_range = builder.sql_query_range
    @sql_query_info  = builder.sql_query_info
    @sql_query_pre  += builder.sql_query_pre

    @prepared = true
  end

  def set_database_settings
    @sql_host ||= database_settings[:host]     || 'localhost'
    @sql_user ||= database_settings[:username] || database_settings[:user]
    @sql_pass ||= database_settings[:password].to_s.gsub('#', '\#')
    @sql_db   ||= database_settings[:database]
    @sql_port ||= database_settings[:port]
    @sql_sock ||= database_settings[:socket]
  end
end

require 'thinking_sphinx/active_record/sql_source/template'
