module ThinkingSphinx::Core::Index
  extend ActiveSupport::Concern

  included do
    attr_reader :reference
    attr_writer :definition_block
  end

  def initialize(reference, options = {})
    @reference  = reference
    @docinfo    = :extern
    @options    = options

    super "#{options[:name] || reference}_#{name_suffix}"
  end

  def delta?
    false
  end

  def document_id_for_key(key)
     key * config.indices.count + offset
  end

  def interpret_definition!
    return if @interpreted_definition || @definition_block.nil?

    @interpreted_definition = true
    interpreter.translate! self, @definition_block
  end

  def model
    @model ||= reference.to_s.camelize.constantize
  end

  def offset
    @offset ||= config.next_offset(reference)
  end

  def render
    pre_render

    @path ||= config.indices_location.join(name)

    super
  end

  def sources
    interpret_definition!
    super
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end

  def name_suffix
    'core'
  end

  def pre_render
    self.class.settings.each do |setting|
      value = config.settings[setting.to_s]
      send("#{setting}=", value) unless value.nil?
    end

    interpret_definition!
  end
end
