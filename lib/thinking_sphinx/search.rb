class ThinkingSphinx::Search < Array
  CORE_METHODS = %w( == class class_eval extend frozen? id instance_eval
    instance_of? instance_values instance_variable_defined?
    instance_variable_get instance_variable_set instance_variables is_a?
    kind_of? member? method methods nil? object_id respond_to?
    respond_to_missing? send should should_not type )
  SAFE_METHODS = %w( partition private_methods protected_methods public_methods
    send class )
  DEFAULT_MIDDLEWARES = [
    ThinkingSphinx::Middlewares::StaleIds,
    ThinkingSphinx::Middlewares::SphinxQL,
    ThinkingSphinx::Middlewares::Geographer,
    ThinkingSphinx::Middlewares::Inquirer,
    ThinkingSphinx::Middlewares::ActiveRecordTranslator,
    ThinkingSphinx::Middlewares::Glazier
  ]

  instance_methods.select { |method|
    method.to_s[/^__/].nil? && !CORE_METHODS.include?(method.to_s)
  }.each { |method|
    undef_method method
  }

  attr_reader :query, :options, :middlewares, :proxies

  def initialize(query = nil, options = {})
    query, options   = nil, query if query.is_a?(Hash)
    @query, @options = query, options
    @middlewares     = @options.delete(:middlewares) || DEFAULT_MIDDLEWARES
    @proxies         = []

    populate if options[:populate]
  end

  def meta
    populate
    context[:meta]
  end

  def offset
    @options[:offset] || ((current_page - 1) * per_page)
  end

  def per_page
    @options[:limit] ||= (@options[:per_page] || 20)
    @options[:limit].to_i
  end

  def populate
    return self if @populated

    middleware_stack.call context
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

  def stale_retries
    @stale_retries ||= case options[:retry_stale]
    when nil, TrueClass
      3
    when FalseClass
      0
    else
      options[:retry_stale].to_i
    end
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
    populate if !SAFE_METHODS.include?(method.to_s)

    context[:results].send(method, *args, &block)
  end

  def middleware_stack
    local_middlewares = middlewares
    @middleware_stack ||= Middleware::Builder.new do
      local_middlewares.each do |mw|
        use mw
      end
    end
  end
end

require 'thinking_sphinx/search/context'
require 'thinking_sphinx/search/excerpt_glaze'
require 'thinking_sphinx/search/geodist'
require 'thinking_sphinx/search/glaze'
require 'thinking_sphinx/search/inquirer'
require 'thinking_sphinx/search/pagination'
require 'thinking_sphinx/search/query'
require 'thinking_sphinx/search/retry_on_stale_ids'
require 'thinking_sphinx/search/scopes'
require 'thinking_sphinx/search/stale_ids_exception'
require 'thinking_sphinx/search/translator'

ThinkingSphinx::Search.send :include, ThinkingSphinx::Search::Pagination
ThinkingSphinx::Search.send :include, ThinkingSphinx::Search::Scopes
