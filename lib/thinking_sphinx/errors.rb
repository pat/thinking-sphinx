class ThinkingSphinx::SphinxError < StandardError
  attr_accessor :statement

  def self.new_from_mysql(error)
    case error.message
    when /parse error/
      replacement = ThinkingSphinx::ParseError.new(error.message)
    when /syntax error/
      replacement = ThinkingSphinx::SyntaxError.new(error.message)
    when /query error/
      replacement = ThinkingSphinx::QueryError.new(error.message)
    when /Can't connect to MySQL server/, /Communications link failure/
      replacement = ThinkingSphinx::ConnectionError.new(
        "Error connecting to Sphinx via the MySQL protocol. #{error.message}"
      )
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

class ThinkingSphinx::SyntaxError < ThinkingSphinx::QueryError
end

class ThinkingSphinx::ParseError < ThinkingSphinx::QueryError
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
