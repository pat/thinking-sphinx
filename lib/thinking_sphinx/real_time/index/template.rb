# frozen_string_literal: true

class ThinkingSphinx::RealTime::Index::Template
  attr_reader :index

  def initialize(index)
    @index = index
  end

  def apply
    add_field class_column, :sphinx_internal_class_name

    add_attribute primary_key,  :sphinx_internal_id,    :bigint
    add_attribute class_column, :sphinx_internal_class, :string, :facet => true
    add_attribute 0,            :sphinx_deleted,        :integer

    if tidying?
      add_attribute -> (_) { Time.current.to_i }, :sphinx_updated_at, :timestamp
    end
  end

  private

  def add_attribute(column, name, type, options = {})
    index.add_attribute ThinkingSphinx::RealTime::Attribute.new(
      ThinkingSphinx::ActiveRecord::Column.new(*column),
      options.merge(:as => name, :type => type)
    )
  end

  def add_field(column, name)
    index.add_field ThinkingSphinx::RealTime::Field.new(
      ThinkingSphinx::ActiveRecord::Column.new(*column), :as => name
    )
  end

  def class_column
    [:class, :name]
  end

  def config
    ThinkingSphinx::Configuration.instance
  end

  def primary_key
    index.primary_key.to_sym
  end

  def tidying?
    config.settings["real_time_tidy"]
  end
end
