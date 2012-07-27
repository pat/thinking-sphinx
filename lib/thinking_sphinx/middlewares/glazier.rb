class ThinkingSphinx::Middlewares::Glazier <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each do |context|
      @context       = context
      @excerpter     = nil
      @excerpt_words = nil

      context[:results] = context[:results].collect { |result|
        ThinkingSphinx::Search::Glaze.new result, excerpter, row_for(result)
      }
    end

    app.call contexts
  end

  private

  def excerpter
    @excerpter ||= ThinkingSphinx::Excerpter.new context[:indices].first.name,
      excerpt_words, (context.search.options[:excerpts] || {})
  end

  def excerpt_words
    @excerpt_words ||= context[:meta].keys.select { |key|
      key[/^keyword\[/]
    }.sort.collect { |key| context[:meta][key] }.join(' ')
  end

  def row_for(result)
    context[:raw].detect { |row|
      row['sphinx_internal_class_attr'] == result.class.name &&
      row['sphinx_internal_id']         == result.id
    }
  end
end
