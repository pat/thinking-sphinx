class ThinkingSphinx::Search < Array
  CoreMethods = %w( == class class_eval extend frozen? id instance_eval
    instance_of? instance_values instance_variable_defined?
    instance_variable_get instance_variable_set instance_variables is_a?
    kind_of? member? method methods nil? object_id respond_to?
    respond_to_missing? send should should_not type )
  SafeMethods = %w( partition private_methods protected_methods public_methods
    send class )

  instance_methods.select { |method|
    method.to_s[/^__/].nil? && !CoreMethods.include?(method.to_s)
  }.each { |method|
    undef_method method
  }

  attr_reader :options, :query

  def initialize(query = nil, options = {})
    query, options   = nil, query if query.is_a?(Hash)
    @query, @options = query, options
    @array           = []

    populate if options[:populate]
  end

  def current_page
    @options[:page] = 1 if @options[:page].blank?
    @options[:page].to_i
  end

  def meta
    inquirer.meta
  end

  def offset
    @options[:offset] || ((current_page - 1) * per_page)
  end

  def page(number)
    @options[:page] = number
    self
  end

  def per(limit)
    @options[:limit] = limit
    self
  end

  def per_page
    @options[:limit] ||= (@options[:per_page] || 20)
    @options[:limit].to_i
  end

  def populate
    return self if @populated

    RetryOnStaleIds.new(self).try_with_stale do
      @array.replace translator.to_active_record
    end
    @populated = true

    self
  end

  def raw
    inquirer.raw
  end

  def reset!
    @inquirer, @translator = nil, nil
  end

  def respond_to?(method, include_private = false)
    super || @array.respond_to?(method, include_private)
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

  private

  def inquirer
    @inquirer ||= ThinkingSphinx::Search::Inquirer.new(self).populate
  end

  def method_missing(method, *args, &block)
    populate if !SafeMethods.include?(method.to_s)

    @array.send(method, *args, &block)
  end

  def translator
    @translator ||= ThinkingSphinx::Search::Translator.new(raw)
  end
end

require 'thinking_sphinx/search/geodist'
require 'thinking_sphinx/search/inquirer'
require 'thinking_sphinx/search/pagination'
require 'thinking_sphinx/search/retry_on_stale_ids'
require 'thinking_sphinx/search/scopes'
require 'thinking_sphinx/search/stale_ids_exception'
require 'thinking_sphinx/search/translator'

ThinkingSphinx::Search.send :include, ThinkingSphinx::Search::Pagination
ThinkingSphinx::Search.send :include, ThinkingSphinx::Search::Scopes
