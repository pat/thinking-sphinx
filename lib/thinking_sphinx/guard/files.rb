class ThinkingSphinx::Guard::Files
  def self.call(names, &block)
    new(names).call(&block)
  end

  def initialize(names)
    @names = names
  end

  def call(&block)
    return if unlocked.empty?

    unlocked.each &:lock
    block.call unlocked.collect(&:name)
    unlocked.each &:unlock
  end

  private

  attr_reader :names

  def unlocked
    @unlocked ||= names.collect { |name|
      ThinkingSphinx::Guard::File.new name
    }.reject &:locked?
  end
end
