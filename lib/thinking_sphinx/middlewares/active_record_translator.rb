# frozen_string_literal: true

class ThinkingSphinx::Middlewares::ActiveRecordTranslator <
  ThinkingSphinx::Middlewares::Middleware

  NO_MODEL = Struct.new(:primary_key).new(:id).freeze
  NO_INDEX = Struct.new(:primary_key).new(:id).freeze

  def call(contexts)
    contexts.each do |context|
      Inner.new(context).call
    end

    app.call contexts
  end

  private

  class Inner
    def initialize(context)
      @context = context
    end

    def call
      results_for_models # load now to avoid segfaults

      context[:results] = if sql_options[:order]
        results_for_models.values.first
      else
        context[:results].collect { |row| result_for(row) }
      end
    end

    private

    attr_reader :context

    def ids_for_model(model_name)
      context[:results].collect { |row|
        row['sphinx_internal_id'] if row['sphinx_internal_class'] == model_name
      }.compact
    end

    def index_for(model)
      return NO_INDEX unless context[:indices]

      context[:indices].detect { |index| index.model == model } || NO_INDEX
    end

    def model_names
      @model_names ||= context[:results].collect { |row|
        row['sphinx_internal_class']
      }.uniq
    end

    def primary_key_for(model)
      model = NO_MODEL unless model.respond_to?(:primary_key)

      @primary_keys        ||= {}
      @primary_keys[model] ||= index_for(model).primary_key
    end

    def reset_memos
      @model_names        = nil
      @results_for_models = nil
    end

    def result_for(row)
      results_for_models[row['sphinx_internal_class']].detect { |record|
        record.public_send(
          primary_key_for(record.class)
        ) == row['sphinx_internal_id']
      }
    end

    def results_for_models
      @results_for_models ||= model_names.inject({}) do |hash, name|
        model = name.constantize

        hash[name] = model_relation_with_sql_options(model.unscoped).where(
          primary_key_for(model) => ids_for_model(name)
        )

        hash
      end
    end

    def model_relation_with_sql_options(relation)
      relation = relation.includes sql_options[:include] if sql_options[:include]
      relation = relation.joins  sql_options[:joins]  if sql_options[:joins]
      relation = relation.order  sql_options[:order]  if sql_options[:order]
      relation = relation.select sql_options[:select] if sql_options[:select]
      relation = relation.group  sql_options[:group]  if sql_options[:group]
      relation = relation.where  sql_options[:where]  if sql_options[:where]
      relation
    end

    def sql_options
      context.search.options[:sql] || {}
    end
  end
end
