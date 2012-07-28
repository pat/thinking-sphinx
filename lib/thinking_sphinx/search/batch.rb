class ThinkingSphinx::Search::Batch
  attr_accessor :searches

  def initialize
    @searches = []
  end

  def populate
    return if populated?

    ThinkingSphinx::Middlewares::DEFAULT.call contexts
    searches.each &:populated!

    @populated = true
  end

  private

  def contexts
    searches.collect &:context
  end

  def populated?
    @populated
  end
end
