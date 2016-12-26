class ThinkingSphinx::SphinxError < StandardError
  attr_accessor :statement

  def self.new_from_mysql(error)
    case error.message
    when /parse error/, /query is non-computable/
      replacement = ThinkingSphinx::ParseError.new(error.message)
    when /syntax error/
      replacement = ThinkingSphinx::SyntaxError.new(error.message)
    when /query error/
      replacement = ThinkingSphinx::QueryError.new(error.message)
    when /Can't connect to MySQL server/, /Communications link failure/
      replacement = ThinkingSphinx::ConnectionError.new(
        "Error connecting to Sphinx via the MySQL protocol. #{error.message}"
      )
    when /offset out of bounds/
      replacement = ThinkingSphinx::OutOfBoundsError.new(error.message)
    else
      replacement = new(error.message)
    end

    replacement.set_backtrace error.backtrace
    replacement.statement = error.statement if error.respond_to?(:statement)
    replacement
  end
end

class ThinkingSphinx::ConnectionError < ThinkingSphinx::SphinxError
end

class ThinkingSphinx::QueryError < ThinkingSphinx::SphinxError
end

class ThinkingSphinx::QueryLengthError < ThinkingSphinx::SphinxError
  def message
    <<-MESSAGE
The supplied SphinxQL statement is #{statement.length} characters long. The maximum allowed length is #{ThinkingSphinx::MAXIMUM_STATEMENT_LENGTH}.

If this error has been raised during real-time index population, it's probably due to overly large batches of records being processed at once. The default is 1000, but you can lower it on a per-environment basis in config/thinking_sphinx.yml:

  development:
    batch_size: 500
    MESSAGE
  end
end

class ThinkingSphinx::SyntaxError < ThinkingSphinx::QueryError
end

class ThinkingSphinx::ParseError < ThinkingSphinx::QueryError
end

class ThinkingSphinx::OutOfBoundsError < ThinkingSphinx::QueryError
end

class ThinkingSphinx::QueryExecutionError < StandardError
  attr_accessor :statement
end

class ThinkingSphinx::MixedScopesError < StandardError
end

class ThinkingSphinx::NoIndicesError < StandardError
end

class ThinkingSphinx::MissingColumnError < StandardError
end

class ThinkingSphinx::PopulatedResultsError < StandardError
end

class ThinkingSphinx::DuplicateNameError < StandardError
end

class ThinkingSphinx::InvalidDatabaseAdapter < StandardError
end

class ThinkingSphinx::SphinxAlreadyRunning < StandardError
end

class ThinkingSphinx::UnknownDatabaseAdapter < StandardError
end

class ThinkingSphinx::UnknownAttributeType < StandardError
end
