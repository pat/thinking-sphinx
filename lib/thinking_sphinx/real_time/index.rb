class ThinkingSphinx::RealTime::Index < Riddle::Configuration::RealtimeIndex
  attr_reader :reference
  attr_writer :definition_block
  attr_accessor :fields, :attributes

  def initialize(reference, options = {})
    @reference  = reference
    @docinfo    = :extern
    @options    = options
    @fields     = []
    @attributes = []

    Template.new(self).apply

    super "#{reference}_core"
  end

  def delta?
    false
  end

  def document_id_for_key(key)
     key * config.indices.count + offset
  end

  def interpret_definition!
    return if @interpreted_definition || @definition_block.nil?

    ThinkingSphinx::RealTime::Interpreter.translate! self, @definition_block
    @interpreted_definition = true
  end

  def model
    @model ||= reference.to_s.camelize.constantize
  end

  def offset
    @offset ||= config.next_offset(reference)
  end

  def render
    self.class.settings.each do |setting|
      value = config.settings[setting.to_s]
      send("#{setting}=", value) unless value.nil?
    end

    interpret_definition!

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

    @path   ||= config.indices_location.join(name)

    super
  end

  def unique_attribute_names
    attributes.collect(&:name)
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end
end

require 'thinking_sphinx/real_time/index/template'
