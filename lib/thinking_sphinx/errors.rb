class ThinkingSphinx::SphinxError < StandardError
  def self.new_from_mysql(error)
    case error.message
    when /parse error/
      replacement = ThinkingSphinx::ParseError.new(error.message)
    when /syntax error/
      replacement = ThinkingSphinx::SyntaxError.new(error.message)
    when /query error/
      replacement = ThinkingSphinx::QueryError.new(error.message)
    else
      replacement = new(error.message)
    end

    replacement.set_backtrace error.backtrace
    replacement
  end
end

class ThinkingSphinx::QueryError < ThinkingSphinx::SphinxError
end

class ThinkingSphinx::SyntaxError < ThinkingSphinx::QueryError
end

class ThinkingSphinx::ParseError < ThinkingSphinx::QueryError
end

class ThinkingSphinx::MixedScopesError < StandardError
end
