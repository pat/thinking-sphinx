module ThinkingSphinx
  module ActiveRecord
    class SQLSource < Riddle::Configuration::SQLSource
      include ThinkingSphinx::Core::Settings
      attr_reader :model, :database_settings, :options
      attr_accessor :fields, :attributes, :associations, :conditions,
        :groupings, :polymorphs

      OPTIONS = [:name, :offset, :delta_processor, :delta?, :delta_options,
        :disable_range?, :group_concat_max_len, :utf8?, :position,
        :minimal_group_by?, :big_document_ids]

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

        apply_defaults!
      end

      def adapter
        @adapter ||= DatabaseAdapters.adapter_for(@model)
      end

      def delta_processor
        options[:delta_processor].try(:new, adapter, @options[:delta_options] || {})
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
        prepare_for_render unless @prepared

        super
      end

      def set_database_settings(settings)
        @sql_host ||= settings[:host]     || 'localhost'
        @sql_user ||= settings[:username] || settings[:user] || ENV['USER']
        @sql_pass ||= settings[:password].to_s.gsub('#', '\#')
        @sql_db   ||= settings[:database]
        @sql_port ||= settings[:port]
        @sql_sock ||= settings[:socket]
        @mysql_ssl_cert ||= settings[:sslcert]
        @mysql_ssl_key  ||= settings[:sslkey]
        @mysql_ssl_ca   ||= settings[:sslca]
      end

      def type
        @type ||= case adapter
        when DatabaseAdapters::MySQLAdapter
          'mysql'
        when DatabaseAdapters::PostgreSQLAdapter
          'pgsql'
        else
          raise "Unknown Adapter Type: #{adapter.class.name}"
        end
      end

      private

      def append_presenter_to_attribute_array
        attributes.each do |attribute|
          presenter = Attribute::SphinxPresenter.new(attribute, self)

          attribute_array_for(presenter.collection_type) << presenter.declaration
        end
      end

      def attribute_array_for(type)
        instance_variable_get "@sql_attr_#{type}".to_sym
      end

      def builder
        @builder ||= SQLBuilder.new self
      end

      def build_sql_fields
        fields.each do |field|
          @sql_field_string        << field.name if field.with_attribute?
          @sql_field_str2wordcount << field.name if field.wordcount?
          @sql_file_field          << field.name if field.file?

          @sql_joined_field << PropertyQuery.new(field, self).to_s if field.source_type
        end
      end

      def build_sql_query
        @sql_query             = builder.sql_query
        @sql_query_range     ||= builder.sql_query_range
        @sql_query_pre        += builder.sql_query_pre
      end

      def config
        ThinkingSphinx::Configuration.instance
      end

      def prepare_for_render
        polymorphs.each &:morph!
        append_presenter_to_attribute_array

        set_database_settings database_settings
        build_sql_fields
        build_sql_query

        @prepared = true
      end

      def properties
        fields + attributes
      end
    end
  end
end

require 'thinking_sphinx/active_record/sql_source/template'
