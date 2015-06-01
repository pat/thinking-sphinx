module ThinkingSphinx::Core::Index
  extend ActiveSupport::Concern
  include ThinkingSphinx::Core::Settings

  included do
    attr_reader :reference, :offset
    attr_writer :definition_block
  end

  def initialize(reference, options = {})
    @reference    = reference.to_sym
    @docinfo      = :extern
    @options      = options
    @offset       = config.next_offset(options[:offset_as] || reference)
    @type         = 'plain'

    super "#{options[:name] || reference.to_s.gsub('/', '_')}_#{name_suffix}"
  end

  def delta?
    false
  end

  def distributed?
    false
  end

  def document_id_for_key(key)
    key * config.indices.count + offset
  end

  def interpret_definition!
    return if @interpreted_definition

    apply_defaults!

    @interpreted_definition = true
    interpreter.translate! self, @definition_block if @definition_block
  end

  def model
    @model ||= reference.to_s.camelize.constantize
  end

  def options
    interpret_definition!
    @options
  end

  def render
    pre_render
    set_path

    assign_infix_fields
    assign_prefix_fields

    super
  end

  private

  def assign_infix_fields
    self.infix_fields  = fields.select(&:infixing?).collect(&:name)
  end

  def assign_prefix_fields
    self.prefix_fields = fields.select(&:prefixing?).collect(&:name)
  end

  def config
    ThinkingSphinx::Configuration.instance
  end

  def name_suffix
    'core'
  end

  def path_prefix
    options[:path] || config.indices_location
  end

  def pre_render
    interpret_definition!
  end

  def set_path
    FileUtils.mkdir_p path_prefix
    @path = File.join path_prefix, name
  end
end
