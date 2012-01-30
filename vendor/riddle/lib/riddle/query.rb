module Riddle::Query
  def self.connection(address = '127.0.0.1', port = 9312)
    require 'mysql2'

    # If you use localhost, MySQL insists on a socket connection, but Sphinx
    # requires a TCP connection. Using 127.0.0.1 fixes that.
    address = '127.0.0.1' if address == 'localhost'

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
      value = options[key]
      value = "'#{value}'" if value.is_a?(String)

      "#{value} AS #{key}"
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
      "#{key} = #{translate_value values[key]}"
    }.join(', ')

    "UPDATE #{index} SET #{values} WHERE id = #{id}"
  end

  def self.translate_value(value)
    case value
    when TrueClass
      1
    when FalseClass
      0
    else
      value
    end
  end
end

require 'riddle/query/delete'
require 'riddle/query/insert'
require 'riddle/query/select'
