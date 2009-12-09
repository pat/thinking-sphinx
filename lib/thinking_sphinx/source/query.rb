class ThinkingSphinx::Source::Query
  def initialize(table, adapter)
    @table   = table
    @adapter = adapter
    @columns = []
    @joins   = []
  end
  
  def add_column(location, column = nil)
    location, column = table, location if column.nil?
    
    @columns << [location, column]
  end
  
  def add_join(from, from_column, to, to_column, name = nil)
    @joins << [from, from_column, to, to_column, name]
  end
  
  def to_s
    "SELECT #{columns} FROM #{adapter.quote table} #{joins}".strip
  end
  
  private
  
  def columns
    return '*' if @columns.empty?
    
    @columns.collect { |location, column|
      "#{adapter.quote location}.#{adapter.quote column}"
    }.join(', ')
  end
  
  def joins
    return '' if @joins.empty?
    
    @joins.collect { |from, from_column, to, to_column, name|
      name ||= to
      "LEFT OUTER JOIN #{adapter.quote to} AS #{adapter.quote name} ON #{adapter.quote from}.#{adapter.quote from_column} = #{adapter.quote name}.#{adapter.quote to_column}"
    }.join(' ')
  end
  
  def adapter
    @adapter
  end
  
  def table
    @table
  end
end
