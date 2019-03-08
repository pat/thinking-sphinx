# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::SourceJoins
  def self.call(model, source)
    new(model, source).call
  end

  def initialize(model, source)
    @model, @source = model, source
  end

  def call
    append_specified_associations
    append_property_associations

    joins
  end

  private

  attr_reader :model, :source

  def append_property_associations
    source.properties.collect(&:columns).each do |columns|
      columns.each { |column| append_column_associations column }
    end
  end

  def append_column_associations(column)
    return if column.__stack.empty? or column_included_in_queries?(column)

    joins.add_join_to column.__stack if column_exists?(column)
  end

  def append_specified_associations
    source.associations.reject(&:string?).each do |association|
      joins.add_join_to association.stack
    end
  end

  def column_exists?(column)
    Joiner::Path.new(model, column.__stack).model
    true
  rescue Joiner::AssociationNotFound
    false
  end

  def joins
    @joins ||= begin
      joins = Joiner::Joins.new model
      if joins.respond_to?(:join_association_class)
        joins.join_association_class = ThinkingSphinx::ActiveRecord::JoinAssociation
      end
      joins
    end
  end

  def source_query_fields
    source.fields.select { |field| field.source_type == :query }
  end

  # Use "first" here instead of a more intuitive flatten because flatten
  # will also ask each column to become an Array and that will start
  # to retrieve data.
  def column_included_in_queries?(column)
    source_query_fields.collect(&:columns).map(&:first).include?(column)
  end
end
