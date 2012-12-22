class ThinkingSphinx::RealTime::Index < Riddle::Configuration::RealtimeIndex
  include ThinkingSphinx::Core::Index

  attr_accessor :fields, :attributes

  def initialize(reference, options = {})
    @fields     = []
    @attributes = []

    Template.new(self).apply

    super reference, options
  end

  def facets
    properties.select(&:facet?)
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
        raise "Unknown attribute type '#{attribute.type(model)}'"
      end
    end
  end

  def properties
    fields + attributes
  end
end

require 'thinking_sphinx/real_time/index/template'
