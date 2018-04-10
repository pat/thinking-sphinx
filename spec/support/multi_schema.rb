# frozen_string_literal: true

class MultiSchema
  def active?
    ENV['DATABASE'] == 'postgresql'
  end

  def create(schema_name)
    return unless active?

    unless connection.schema_exists? schema_name
      connection.execute %Q{CREATE SCHEMA "#{schema_name}"}
    end

    switch schema_name
    load Rails.root.join('db', 'schema.rb')
  end

  def current
    connection.schema_search_path
  end

  def switch(schema_name)
    connection.schema_search_path = %Q{"#{schema_name}"}
    connection.clear_query_cache
  end

  private

  def connection
    ActiveRecord::Base.connection
  end

  class IndexSet < ThinkingSphinx::IndexSet
    private

    def indices
      return super if index_names.any?

      prefixed = !multi_schema.current.include?('public')
      super.select { |index|
        prefixed ? index.name[/_two_core$/] : index.name[/_two_core$/].nil?
      }
    end

    def multi_schema
      @multi_schema ||= MultiSchema.new
    end
  end
end
