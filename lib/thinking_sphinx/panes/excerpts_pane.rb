class ThinkingSphinx::Panes::ExcerptsPane
  def initialize(context, object, raw)
    @context, @object = context, object
  end

  def excerpts
    @excerpt_glazing ||= Excerpts.new @object, excerpter
  end

  private

  def excerpter
    @excerpter ||= ThinkingSphinx::Excerpter.new(
      @context[:indices].first.name,
      excerpt_words,
      @context.search.options[:excerpts] || {}
    )
  end

  def excerpt_words
    @excerpt_words ||= @context[:meta].keys.select { |key|
      key[/^keyword\[/]
    }.sort.collect { |key| @context[:meta][key] }.join(' ')
  end

  class Excerpts
    def initialize(object, excerpter)
      @object, @excerpter = object, excerpter
    end

    private

    def method_missing(method, *args, &block)
      @excerpter.excerpt! @object.send(method, *args, &block).to_s
    end
  end
end
