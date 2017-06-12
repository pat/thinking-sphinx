class ThinkingSphinx::Connection::JRuby < ThinkingSphinx::Connection::Client
  attr_reader :address, :options

  def initialize(options)
    @address = "jdbc:mysql://#{options[:host]}:#{options[:port]}/?allowMultiQueries=true"
    @options = options
  end

  def base_error
    Java::JavaSql::SQLException
  end

  private

  def client
    @client ||= begin
      properties = Java::JavaUtil::Properties.new
      properties.setProperty "user", options[:username] if options[:username]
      properties.setProperty "password", options[:password] if options[:password]
      Java::ComMysqlJdbc::Driver.new.connect "jdbc:mysql://127.0.0.1:9307/?allowMultiQueries=true", properties
    end
  rescue base_error => error
    raise ThinkingSphinx::SphinxError.new_from_mysql error
  end

  def results_for(statements)
    statement = client.createStatement
    statement.execute statements

    results   = [set_to_array(statement.getResultSet)]
    results  << set_to_array(statement.getResultSet) while statement.getMoreResults
    results.compact
  end

  def set_to_array(set)
    return nil if set.nil?

    meta = set.getMetaData
    rows = []

    while set.next
      rows << (1..meta.getColumnCount).inject({}) do |row, index|
        name      = meta.getColumnName index
        row[name] = set.getObject(index)
        row
      end
    end

    rows
  end
end
