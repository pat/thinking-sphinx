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
    ThinkingSphinx::Masks::ScopesMask,
    ThinkingSphinx::Masks::GroupEnumeratorsMask
  ]

  instance_methods.select { |method|
    method.to_s[/^__/].nil? && !CORE_METHODS.include?(method.to_s)
  }.each { |method|
    undef_method method
  }

  attr_reader   :options
  attr_accessor :query

  def self.valid_options
    @valid_options
  end

  @valid_options = [
    :classes, :conditions, :geo, :group_by, :ids_only, :ignore_scopes, :indices,
    :limit, :masks, :max_matches, :middleware, :offset, :order, :order_group_by,
    :page, :per_page, :populate, :retry_stale, :select, :skip_sti, :sql, :star,
    :with, :with_all, :without, :without_ids
  ]

  def initialize(query = nil, options = {})
    query, options   = nil, query if query.is_a?(Hash)
    @query, @options = query, options

    populate if options[:populate]
  end

  def context
    @context ||= ThinkingSphinx::Search::Context.new self,
      ThinkingSphinx::Configuration.instance
  end

  def current_page
    options[:page] = 1 if options[:page].blank?
    options[:page].to_i
  end

  def marshal_dump
    populate

    [@populated, @query, @options, @context]
  end

  def marshal_load(array)
    @populated, @query, @options, @context = array
  end

  def masks
    @masks ||= @options[:masks] || DEFAULT_MASKS.clone
  end

  def meta
    populate
    context[:meta]
  end

  def offset
    @options[:offset] || ((current_page - 1) * per_page)
  end

  alias_method :offset_value, :offset

  def per_page(value = nil)
    @options[:limit] = value unless value.nil?
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

  def populated?
    @populated
  end

  def query_time
    meta['time'].to_f
  end

  def raw
    populate
    context[:raw]
  end

  def to_a
    populate
    context[:results].collect { |result|
      result.respond_to?(:unglazed) ? result.unglazed : result
    }
  end

  private

  def default_middleware
    options[:ids_only] ? ThinkingSphinx::Middlewares::IDS_ONLY :
      ThinkingSphinx::Middlewares::DEFAULT
  end

  def mask_stack
    @mask_stack ||= masks.collect { |klass| klass.new self }
  end

  def masks_respond_to?(method)
    mask_stack.any? { |mask| mask.can_handle? method }
  end

  def method_missing(method, *args, &block)
    mask_stack.each do |mask|
      return mask.send(method, *args, &block) if mask.can_handle?(method)
    end

    populate if !SAFE_METHODS.include?(method.to_s)

    context[:results].send(method, *args, &block)
  end

  def respond_to_missing?(method, include_private = false)
    super ||
      masks_respond_to?(method) ||
      results_respond_to?(method, include_private)
  end

  def middleware
    @options[:middleware] || default_middleware
  end

  def results_respond_to?(method, include_private = true)
    context[:results].respond_to?(method, include_private)
  end
end

require 'thinking_sphinx/search/batch_inquirer'
require 'thinking_sphinx/search/context'
require 'thinking_sphinx/search/glaze'
require 'thinking_sphinx/search/merger'
require 'thinking_sphinx/search/query'
require 'thinking_sphinx/search/stale_ids_exception'
