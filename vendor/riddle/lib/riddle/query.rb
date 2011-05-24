module Riddle::Query
  def self.connection(address = 'localhost', port = 9312)
    require 'mysql2'
    
    Mysql2::Client.new(
      :host => address,
      :port => port
    )
  end
  
  def self.meta
    'SHOW META'
  end
  
  def self.warnings
    'SHOW WARNINGS'
  end
  
  def self.status
    'SHOW STATUS'
  end
  
  def self.tables
    'SHOW TABLES'
  end
  
  def self.variables
    'SHOW VARIABLES'
  end
  
  def self.collation
    'SHOW COLLATION'
  end
  
  def self.describe(index)
    "DESCRIBE #{index}"
  end
  
  def self.begin
    'BEGIN'
  end
  
  def self.commit
    'COMMIT'
  end
  
  def self.rollback
    'ROLLBACK'
  end
  
  def self.set(variable, values, global = true)
    values = "(#{values.join(', ')})" if values.is_a?(Array)
    "SET#{ ' GLOBAL' if global } #{variable} = #{values}"
  end
  
  def self.snippets(data, index, query, options = nil)
    options = ', ' + options.keys.collect { |key|
      "#{options[key]} AS #{key}"
    }.join(', ') unless options.nil?
    
    "CALL SNIPPETS('#{data}', '#{index}', '#{query}'#{options})"
  end
  
  def self.create_function(name, type, file)
    type = type.to_s.upcase
    "CREATE FUNCTION #{name} RETURNS #{type} SONAME '#{file}'"
  end
  
  def self.drop_function(name)
    "DROP FUNCTION #{name}"
  end
  
  def self.update(index, id, values = {})
    values = values.keys.collect { |key|
      "#{key} = #{values[key]}"
    }.join(', ')
    
    "UPDATE #{index} SET #{values} WHERE id = #{id}"
  end
end

require 'riddle/query/delete'
require 'riddle/query/insert'
require 'riddle/query/select'
