class ThinkingSphinx::Search < Array
  CORE_METHODS = %w( == class class_eval extend frozen? id instance_eval
    instance_of? instance_values instance_variable_defined?
    instance_variable_get instance_variable_set instance_variables is_a?
    kind_of? member? method methods nil? object_id respond_to?
    respond_to_missing? send should should_not type )
  SAFE_METHODS = %w( partition private_methods protected_methods public_methods
    send class )
  DEFAULT_MASKS = [
    ThinkingSphinx::Masks::PaginationMask,
    ThinkingSphinx::Masks::ScopesMask
  ]

  instance_methods.select { |method|
    method.to_s[/^__/].nil? && !CORE_METHODS.include?(method.to_s)
  }.each { |method|
    undef_method method
  }

  attr_reader   :options, :masks
  attr_accessor :query

  def initialize(query = nil, options = {})
    query, options   = nil, query if query.is_a?(Hash)
    @query, @options = query, options
    @masks           = @options.delete(:masks) || DEFAULT_MASKS
    @middleware      = @options.delete(:middleware)

    populate if options[:populate]
  end

  def context
    @context ||= ThinkingSphinx::Search::Context.new self,
      ThinkingSphinx::Configuration.instance
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

    middleware.call [context]
    @populated = true

    self
  end

  def populated!
    @populated = true
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
    context[:results].collect { |result|
      result.respond_to?(:unglazed) ? result.unglazed : result
    }
  end

  private

  def mask_stack
    @mask_stack ||= masks.collect { |klass| klass.new self }
  end

  def method_missing(method, *args, &block)
    mask_stack.each do |mask|
      return mask.send(method, *args, &block) if mask.respond_to?(method)
    end

    populate if !SAFE_METHODS.include?(method.to_s)

    context[:results].send(method, *args, &block)
  end

  def middleware
    @middleware ||= begin
      if options[:ids_only]
        ThinkingSphinx::Middlewares::IDS_ONLY
      else
        ThinkingSphinx::Middlewares::DEFAULT
      end
    end
  end
end

require 'thinking_sphinx/search/batch'
require 'thinking_sphinx/search/batch_inquirer'
require 'thinking_sphinx/search/context'
require 'thinking_sphinx/search/excerpt_glaze'
require 'thinking_sphinx/search/glaze'
require 'thinking_sphinx/search/merger'
require 'thinking_sphinx/search/query'
require 'thinking_sphinx/search/stale_ids_exception'
