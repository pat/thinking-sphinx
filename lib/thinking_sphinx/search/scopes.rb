module ThinkingSphinx::Search::Scopes
  def self.included(base)
    base.instance_eval do
      alias_method :method_missing_without_scope, :method_missing
      alias_method :method_missing,               :method_missing_with_scope
    end
  end

  def search(query = nil, options = {})
    query, options = nil, query if query.is_a?(Hash)
    merge! query, options
    self
  end

  private

  def apply_scope(scope, *args)
    search *sphinx_scopes[scope].call(*args)
  end

  def can_apply_scope?(scope)
    options[:classes].present?    &&
    options[:classes].length == 1 &&
    options[:classes].first.respond_to?(:sphinx_scopes)   &&
    sphinx_scopes[scope].present?
  end

  def merge!(query, options)
    @query = query unless query.nil?
    options.each do |key, value|
      case key
      when :conditions, :with, :without
        @options[key] ||= {}
        @options[key].merge! value
      when :without_ids
        @options[key] ||= []
        @options[key] += value
      else
        @options[key] = value
      end
    end
  end

  def method_missing_with_scope(method, *args, &block)
    if can_apply_scope? method
      apply_scope method, *args
    else
      method_missing_without_scope method, *args, &block
    end
  end

  def sphinx_scopes
    options[:classes].first.sphinx_scopes
  end
end
