class ThinkingSphinx::Search::Batch
  def initialize
    @searches = []
  end

  def search(*args)
    @searches << ThinkingSphinx.search(*args)
  end

  def searches
    populate
    @searches
  end

  private

  def contexts
    @searches.collect &:context
  end

  def populated?
    @populated
  end

  def populate
    return if populated?

    ThinkingSphinx::Middlewares::DEFAULT.call contexts
    @searches.each &:populated!

    @populated = true
  end
end
