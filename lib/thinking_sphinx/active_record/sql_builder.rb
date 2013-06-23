module ThinkingSphinx
  module ActiveRecord
    class SQLBuilder
      attr_reader :source

      def initialize(source)
        @source = source
      end

      def sql_query
        query = relation.select pre_select + select_clause
        query = query.where where_clause
        query = query.group group_clause
        query = query.order('NULL') if source.type == 'mysql'
        query = query.joins associations.join_values
        query = query.joins custom_joins if custom_joins.any?

        query.to_sql.gsub(/\n/, "\\\n")
      end

      def sql_query_range
        return nil if source.disable_range?

        minimum = convert_nulls "MIN(#{quoted_primary_key})", 1
        maximum = convert_nulls "MAX(#{quoted_primary_key})", 1

        relation.select("#{minimum}, #{maximum}").where(where_clause(true)).to_sql
      end

      def sql_query_info
        relation.where("#{quoted_primary_key} = #{reversed_document_id}").to_sql
      end

      def sql_query_pre
        queries = []

        queries << delta_processor.reset_query if delta_processor && !source.delta?
        if max_len = source.options[:group_concat_max_len]
          queries << "SET SESSION group_concat_max_len = #{max_len}"
        end
        queries += utf8_query_pre if source.options[:utf8?]

        queries.compact
      end

      private

      def config
        ThinkingSphinx::Configuration.instance
      end

      delegate :adapter, :model, :delta_processor, :to => :source
      delegate :convert_nulls, :utf8_query_pre, :to => :adapter
      def relation
        model.unscoped
      end

      def base_join
        @base_join ||= join_dependency_class.new model, [], initial_joins
      end

      def associations
        @associations ||= ThinkingSphinx::ActiveRecord::Associations.new(model).tap do |assocs|
          source.associations.reject(&:string?).each do |association|
            assocs.add_join_to association.stack
          end
        end
      end

      def custom_joins
        @custom_joins ||= source.associations.select(&:string?).collect(&:to_s)
      end

      def quote_column(column)
        model.connection.quote_column_name(column)
      end

      def quoted_primary_key
        "#{model.quoted_table_name}.#{quote_column(source.primary_key)}"
      end

      def quoted_inheritance_column
        "#{model.quoted_table_name}.#{quote_column(model.inheritance_column)}"
      end

      def pre_select
        ('SQL_NO_CACHE ' if source.type == 'mysql').to_s
      end

      def document_id
        quoted_alias = quote_column source.primary_key
        "#{quoted_primary_key} * #{config.indices.count} + #{source.offset} AS #{quoted_alias}"
      end

      def reversed_document_id
        "($id - #{source.offset}) / #{config.indices.count}"
      end

      def attribute_presenters
        @attribute_presenters ||= property_sql_presenters_for(source.attributes)
      end

      def field_presenters
        @field_presenters ||= property_sql_presenters_for(source.fields)
      end

      def property_sql_presenters_for(fields)
        fields.collect { |field| property_sql_presenter_for(field) }
      end

      def property_sql_presenter_for(field)
        ThinkingSphinx::ActiveRecord::PropertySQLPresenter.new(
          field, source.adapter, associations
        )
      end

      def comma_separated(clauses)
        clauses.flatten.compact.join(', ')
      end

      def select_clause
        comma_separated [
          document_id,
          field_presenters.collect(&:to_select),
          attribute_presenters.collect(&:to_select),
        ]
      end

      def where_clause(for_range = false)
        logic = []

        unless model.descends_from_active_record?
          logic << "#{quoted_inheritance_column} = '#{model_name}'"
        end

        logic << delta_processor.clause(source.delta?) if delta_processor

        unless for_range
          logic << "#{quoted_primary_key} BETWEEN $start AND $end" unless source.disable_range?
          logic += source.conditions
        end

        logic.compact.join(' AND ')
      end

      def group_clause
        comma_separated [
          quoted_primary_key,
          field_presenters.collect(&:to_group),
          attribute_presenters.collect(&:to_group),
          groupings
        ]
      end

      def groupings
        clauses = source.groupings
        if model.column_names.include?(model.inheritance_column)
          clauses << quoted_inheritance_column
        end
        clauses
      end

      def model_name
        klass = model.name
        klass = klass.demodulize unless model.store_full_sti_class
        klass
      end
    end
  end
end
