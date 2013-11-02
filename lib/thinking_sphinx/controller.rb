class ThinkingSphinx::Controller < Riddle::Controller
  def index(*indices)
    options = indices.extract_options!
    indices << '--all' if indices.empty?

    indices = indices.reject { |index| File.exists? guard_file(index) }
    return if indices.empty?

    indices.each { |index| FileUtils.touch guard_file(index) }
    super(*(indices + [options]))
    indices.each { |index| FileUtils.rm guard_file(index) }
  end

  def guard_file(index)
    File.join(
      ThinkingSphinx::Configuration.instance.indices_location,
      "ts-#{index}.tmp"
    )
  end
end
