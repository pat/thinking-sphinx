class ThinkingSphinx::Guard::File
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def lock
    FileUtils.touch file_name
  end

  def locked?
    File.exists? file_name
  end

  def unlock
    FileUtils.rm file_name
  end

  private

  def file_name
    @file_name ||= File.join(
      ThinkingSphinx::Configuration.instance.indices_location,
      "ts-#{name}.tmp"
    )
  end
end
