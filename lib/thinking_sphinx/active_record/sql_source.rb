class ThinkingSphinx::ActiveRecord::SQLSource < Riddle::Configuration::SQLSource
  attr_reader :model, :database_settings, :options
  attr_accessor :fields, :attributes, :associations, :conditions, :groupings,
    :polymorphs

  OPTIONS = [:name, :offset, :delta_processor, :delta?, :disable_range?,
    :group_concat_max_len, :utf8?, :position]

  def initialize(model, options = {})
    @model             = model
    @database_settings = model.connection.instance_variable_get(:@config).clone
    @options           = {
      :utf8? => (@database_settings[:encoding] == 'utf8')
    }.merge options

    @fields            = []
    @attributes        = []
    @associations      = []
    @conditions        = []
    @groupings         = []
    @polymorphs        = []

    Template.new(self).apply

    name = "#{options[:name] || model.name.downcase}_#{options[:position]}"

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

  def facets
    properties.select(&:facet?)
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

  def prepare_for_render
    polymorphs.each &:morph!

    set_database_settings

    fields.each do |field|
      @sql_field_string        << field.name if field.with_attribute?
      @sql_field_str2wordcount << field.name if field.wordcount?
      @sql_file_field          << field.name if field.file?

      @sql_joined_field << ThinkingSphinx::ActiveRecord::PropertyQuery.new(
        field, self
      ).to_s if field.source_type
    end

    attributes.each do |attribute|
      presenter = ThinkingSphinx::ActiveRecord::Attribute::SphinxPresenter.new(attribute, self)

      attribute_array_for(presenter.collection_type) << presenter.declaration
    end

    @sql_query       = builder.sql_query
    @sql_query_range = builder.sql_query_range
    @sql_query_info  = builder.sql_query_info
    @sql_query_pre  += builder.sql_query_pre

    @prepared = true
  end

  def properties
    fields + attributes
  end

  def set_database_settings
    @sql_host ||= database_settings[:host]     || 'localhost'
    @sql_user ||= database_settings[:username] || database_settings[:user] ||
      ENV['USER']
    @sql_pass ||= database_settings[:password].to_s.gsub('#', '\#')
    @sql_db   ||= database_settings[:database]
    @sql_port ||= database_settings[:port]
    @sql_sock ||= database_settings[:socket]
  end
end

require 'thinking_sphinx/active_record/sql_source/template'
