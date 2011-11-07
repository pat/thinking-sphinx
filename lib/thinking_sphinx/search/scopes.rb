module ThinkingSphinx::Search::Scopes
  def self.included(base)
    base.instance_eval do
      alias_method :method_missing_without_scope, :method_missing
      alias_method :method_missing,               :method_missing_with_scope
    end
  end

  private

  def apply_scope(scope, *args)
    query, options = sphinx_scopes[scope].call(*args)
    query, options = nil, query if query.is_a?(Hash)

    @query = query
    options.each do |key, value|
      case key
      when :conditions, :with, :without
        @options[key] ||= {}
        @options[key].merge! value
      when :without_ids
        @options[key] ||= []
        @options[key] << value
      else
        @options[key] = value
      end
    end
  end

  def can_apply_scope?(scope)
    options[:classes].present?    &&
    options[:classes].length == 1 &&
    options[:classes].first.respond_to?(:sphinx_scopes)   &&
    sphinx_scopes[scope].present?
  end

  def method_missing_with_scope(method, *args, &block)
    if can_apply_scope? method
      apply_scope method, *args and self
    else
      method_missing_without_scope method, *args, &block
    end
  end

  def sphinx_scopes
    options[:classes].first.sphinx_scopes
  end
end
