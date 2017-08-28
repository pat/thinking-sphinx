class ThinkingSphinx::Middlewares::AttributeTyper <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each do |context|
      deprecate_filters_in context.search.options[:with]
      deprecate_filters_in context.search.options[:without]
      deprecate_filters_in context.search.options[:with_all]
      deprecate_filters_in context.search.options[:without_all]
    end

    app.call contexts
  end

  private

  def attributes
    @attributes ||= ThinkingSphinx::AttributeTypes.call
  end

  def casted_value_for(type, value)
    case type
    when :uint, :bigint, :timestamp, :bool
      value.to_i
    when :float
      value.to_f
    else
      value
    end
  end

  def deprecate_filters_in(filters)
    return if filters.nil?

    filters.each do |key, value|
      known_types = attributes[key.to_s] || [:string]

      next unless value.is_a?(String) && !known_types.include?(:string)

      ActiveSupport::Deprecation.warn(<<-MSG.squish, caller(11))
You are filtering on a non-string attribute #{key} with a string value (#{value.inspect}).
  Thinking Sphinx will quote string values by default in upcoming releases (which will cause query syntax errors on non-string attributes), so please cast these values to their appropriate types.
      MSG

      filters[key] = casted_value_for known_types.first, value
    end
  end
end
