# frozen_string_literal: true

class ThinkingSphinx::Guard::File
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def lock
    FileUtils.touch path
  end

  def locked?
    File.exists? path
  end

  def path
    @path ||= File.join(
      ThinkingSphinx::Configuration.instance.indices_location,
      "ts-#{name}.tmp"
    )
  end

  def unlock
    FileUtils.rm(path) if locked?
  end
end
