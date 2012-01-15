class ThinkingSphinx::Search::ExcerptGlaze < BlankSlate
  def initialize(object, excerpter)
    @object, @excerpter = object, excerpter
  end

  private

  def method_missing(method, *args, &block)
    @excerpter.excerpt! @object.send(method, *args, &block).to_s
  end
end
