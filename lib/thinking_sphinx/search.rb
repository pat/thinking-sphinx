class ThinkingSphinx::Search < Array
  CORE_METHODS = %w( == class class_eval extend frozen? id instance_eval
    instance_of? instance_values instance_variable_defined?
    instance_variable_get instance_variable_set instance_variables is_a?
    kind_of? member? method methods nil? object_id respond_to?
    respond_to_missing? send should should_not type )
  SAFE_METHODS = %w( partition private_methods protected_methods public_methods
    send class )
  DEFAULT_MIDDLEWARES = [
    ThinkingSphinx::Middlewares::StaleIdFilter,
    ThinkingSphinx::Middlewares::SphinxQL,
    ThinkingSphinx::Middlewares::Geographer,
    ThinkingSphinx::Middlewares::Inquirer,
    ThinkingSphinx::Middlewares::ActiveRecordTranslator,
    ThinkingSphinx::Middlewares::StaleIdChecker,
    ThinkingSphinx::Middlewares::Glazier
  ]
  DEFAULT_MASKS = [
    ThinkingSphinx::Masks::PaginationMask,
    ThinkingSphinx::Masks::ScopesMask
  ]

  instance_methods.select { |method|
    method.to_s[/^__/].nil? && !CORE_METHODS.include?(method.to_s)
  }.each { |method|
    undef_method method
  }

  attr_reader   :options, :middlewares, :masks
  attr_accessor :query

  def initialize(query = nil, options = {})
    query, options   = nil, query if query.is_a?(Hash)
    @query, @options = query, options
    @middleware      = @options.delete(:middleware) ||
      ThinkingSphinx::Configuration.instance.middleware
    @masks           = @options.delete(:masks)      || DEFAULT_MASKS

    populate if options[:populate]
  end

  def meta
    populate
    context[:meta]
  end

  def offset
    @options[:offset] || ((current_page - 1) * per_page)
  end

  alias_method :offset_value, :offset

  def per_page
    @options[:limit] ||= (@options[:per_page] || 20)
    @options[:limit].to_i
  end

  alias_method :limit_value, :per_page

  def populate
    return self if @populated

    @middleware.call context
    @populated = true

    self
  end

  def raw
    populate
    context[:raw]
  end

  def respond_to?(method, include_private = false)
    super || context[:results].respond_to?(method, include_private)
  end

  def to_a
    populate
    context[:results].collect &:unglazed
  end

  private

  def context
    @context ||= ThinkingSphinx::Search::Context.new self,
      ThinkingSphinx::Configuration.instance
  end

  def method_missing(method, *args, &block)
    mask_stack.each do |mask|
      return mask.send(method, *args, &block) if mask.respond_to?(method)
    end

    populate if !SAFE_METHODS.include?(method.to_s)

    context[:results].send(method, *args, &block)
  end

  def mask_stack
    @mask_stack ||= masks.collect { |klass| klass.new self }
  end
end

require 'thinking_sphinx/search/batch_inquirer'
require 'thinking_sphinx/search/context'
require 'thinking_sphinx/search/excerpt_glaze'
require 'thinking_sphinx/search/glaze'
require 'thinking_sphinx/search/query'
require 'thinking_sphinx/search/stale_ids_exception'
