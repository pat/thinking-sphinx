class Riddle::Query::Select
  def initialize
    @values                = ['*']
    @indices               = []
    @matching              = nil
    @wheres                = {}
    @where_alls            = {}
    @where_nots            = {}
    @where_not_alls        = {}
    @group_by              = nil
    @order_by              = nil
    @order_within_group_by = nil
    @offset                = nil
    @limit                 = nil
    @options               = {}
  end

  def values(*values)
    @values += values
    self
  end

  def from(*indices)
    @indices += indices
    self
  end

  def matching(match)
    @matching = match
    self
  end

  def where(filters = {})
    @wheres.merge!(filters)
    self
  end

  def where_all(filters = {})
    @where_alls.merge!(filters)
    self
  end

  def where_not(filters = {})
    @where_nots.merge!(filters)
    self
  end

  def where_not_all(filters = {})
    @where_not_alls.merge!(filters)
    self
  end

  def group_by(attribute)
    @group_by = attribute
    self
  end

  def order_by(order)
    @order_by = order
    self
  end

  def order_within_group_by(order)
    @order_within_group_by = order
    self
  end

  def limit(limit)
    @limit = limit
    self
  end

  def offset(offset)
    @offset = offset
    self
  end

  def with_options(options = {})
    @options.merge! options
    self
  end

  def to_sql
    sql = "SELECT #{ @values.join(', ') } FROM #{ @indices.join(', ') }"
    sql << " WHERE #{ combined_wheres }" if wheres?
    sql << " GROUP BY #{@group_by}"      if !@group_by.nil?
    sql << " ORDER BY #{@order_by}"      if !@order_by.nil?
    unless @order_within_group_by.nil?
      sql << " WITHIN GROUP ORDER BY #{@order_within_group_by}"
    end
    sql << " #{limit_clause}"   unless @limit.nil? && @offset.nil?
    sql << " #{options_clause}" unless @options.empty?

    sql
  end

  private

  def wheres?
    !(@wheres.empty? && @where_alls.empty? && @where_nots.empty? && @where_not_alls.empty? && @matching.nil?)
  end

  def combined_wheres
    if @matching.nil?
      wheres_to_s
    elsif @wheres.empty? && @where_nots.empty? && @where_alls.empty? && @where_not_alls.empty?
      "MATCH('#{@matching}')"
    else
      "MATCH('#{@matching}') AND #{wheres_to_s}"
    end
  end

  def wheres_to_s
    (
      @wheres.keys.collect { |key|
        filter_comparison_and_value key, @wheres[key]
      } +
      @where_alls.collect { |key, values|
        values.collect { |value|
          filter_comparison_and_value key, value
        }
      } +
      @where_nots.keys.collect { |key|
        exclusive_filter_comparison_and_value key, @where_nots[key]
      } +
      @where_not_alls.collect { |key, values|
        '(' + values.collect { |value|
          exclusive_filter_comparison_and_value key, value
        }.join(' OR ') + ')'
      }
    ).flatten.join(' AND ')
  end

  def filter_comparison_and_value(attribute, value)
    case value
    when Array
      "#{attribute} IN (#{value.collect { |val| filter_value(val) }.join(', ')})"
    when Range
      "#{attribute} BETWEEN #{filter_value(value.first)} AND #{filter_value(value.last)}"
    else
      "#{attribute} = #{filter_value(value)}"
    end
  end

  def exclusive_filter_comparison_and_value(attribute, value)
    case value
    when Array
      "#{attribute} NOT IN (#{value.collect { |val| filter_value(val) }.join(', ')})"
    when Range
      "#{attribute} < #{filter_value(value.first)} OR #{attribute} > #{filter_value(value.last)}"
    else
      "#{attribute} <> #{filter_value(value)}"
    end
  end

  def filter_value(value)
    case value
    when TrueClass
      1
    when FalseClass
      0
    when Time
      value.to_i
    else
      value
    end
  end

  def limit_clause
    if @offset.nil?
      "LIMIT #{@limit}"
    else
      "LIMIT #{@offset}, #{@limit || 20}"
    end
  end

  def options_clause
    'OPTION ' + @options.keys.collect { |key|
      "#{key}=#{option_value @options[key]}"
    }.join(', ')
  end

  def option_value(value)
    case value
    when Hash
      '(' + value.collect { |key, value| "#{key}=#{value}" }.join(', ') + ')'
    else
      value
    end
  end
end
