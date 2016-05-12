class ThinkingSphinx::RealTime::Index < Riddle::Configuration::RealtimeIndex
  include ThinkingSphinx::Core::Index

  attr_writer :fields, :attributes, :conditions, :scope

  def initialize(reference, options = {})
    @fields     = []
    @attributes = []
    @conditions = []

    Template.new(self).apply

    super reference, options
  end

  def add_attribute(attribute)
    @attributes << attribute
  end

  def add_field(field)
    @fields << field
  end

  def attributes
    interpret_definition!

    @attributes
  end

  def conditions
    interpret_definition!

    @conditions
  end

  def facets
    properties.select(&:facet?)
  end

  def fields
    interpret_definition!

    @fields
  end

  def scope
    @scope.nil? ? model : @scope.call
  end

  def unique_attribute_names
    attributes.collect(&:name)
  end

  private

  def append_unique_attribute(collection, attribute)
    collection << attribute.name unless collection.include?(attribute.name)
  end

  def collection_for(attribute)
    case attribute.type
    when :integer, :boolean
      attribute.multi? ? @rt_attr_multi : @rt_attr_uint
    when :string
      @rt_attr_string
    when :timestamp
      @rt_attr_timestamp
    when :float
      @rt_attr_float
    when :bigint
      attribute.multi? ? @rt_attr_multi_64 : @rt_attr_bigint
    when :json
      @rt_attr_json
    else
      raise "Unknown attribute type '#{attribute.type}'"
    end
  end

  def interpreter
    ThinkingSphinx::RealTime::Interpreter
  end

  def pre_render
    super

    @rt_field = fields.collect &:name

    attributes.each do |attribute|
      append_unique_attribute collection_for(attribute), attribute
    end
  end

  def properties
    fields + attributes
  end
end

require 'thinking_sphinx/real_time/index/template'
