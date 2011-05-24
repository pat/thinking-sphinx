class Riddle::Query::Select
  def initialize
    @indices               = []
    @matching              = nil
    @wheres                = {}
    @group_by              = nil
    @order_by              = nil
    @order_within_group_by = nil
    @offset                = nil
    @limit                 = nil
    @options               = {}
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
    sql = "SELECT * FROM #{ @indices.join(', ') }"
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
    !(@wheres.empty? && @matching.nil?)
  end

  def combined_wheres
    if @matching.nil?
      wheres_to_s
    elsif @wheres.empty?
      "MATCH('#{@matching}')"
    else
      "MATCH('#{@matching}') AND #{wheres_to_s}"
    end
  end

  def wheres_to_s
    @wheres.keys.collect { |key|
      "#{key} = #{@wheres[key]}"
    }.join(' AND ')
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
      "#{key}=#{@options[key]}"
    }.join(', ')
  end
end
