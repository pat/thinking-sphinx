class ThinkingSphinx::RealTime::Index < Riddle::Configuration::RealtimeIndex
  include ThinkingSphinx::Core::Index

  attr_writer :fields, :attributes, :conditions

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

  def unique_attribute_names
    attributes.collect(&:name)
  end

  private

  def interpreter
    ThinkingSphinx::RealTime::Interpreter
  end

  def pre_render
    super

    @rt_field = fields.collect &:name

    attributes.each do |attribute|
      case attribute.type
      when :integer, :boolean
        @rt_attr_uint << attribute.name unless @rt_attr_uint.include?(attribute.name)
      when :string
        @rt_attr_string << attribute.name unless @rt_attr_string.include?(attribute.name)
      when :timestamp
        @rt_attr_timestamp << attribute.name unless @rt_attr_timestamp.include?(attribute.name)
      when :float
        @rt_attr_float << attribute.name unless @rt_attr_float.include?(attribute.name)
      else
        raise "Unknown attribute type '#{attribute.type}'"
      end
    end
  end

  def properties
    fields + attributes
  end
end

require 'thinking_sphinx/real_time/index/template'
