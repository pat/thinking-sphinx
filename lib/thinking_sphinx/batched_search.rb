# frozen_string_literal: true

class ThinkingSphinx::BatchedSearch
  attr_accessor :searches

  def initialize
    @searches = []
  end

  def populate(middleware = ThinkingSphinx::Middlewares::DEFAULT)
    return if populated? || searches.empty?

    middleware.call contexts
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
