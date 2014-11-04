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
  rescue => error
    raise error
  ensure
    unlocked.each &:unlock
  end

  private

  attr_reader :names

  def log_lock(file)
    ThinkingSphinx::Logger.log :guard,
      "Guard file for index #{file.name} exists, not indexing: #{file.path}."
  end

  def unlocked
    @unlocked ||= names.collect { |name|
      ThinkingSphinx::Guard::File.new name
    }.reject { |file|
      log_lock file if file.locked?
      file.locked?
    }
  end
end
