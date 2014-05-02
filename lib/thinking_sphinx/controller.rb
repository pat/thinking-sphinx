class ThinkingSphinx::Controller < Riddle::Controller
  def index(*indices)
    options = indices.extract_options!
    indices << '--all' if indices.empty?

    indices = indices.reject { |index| File.exists? guard_file(index) }
    return if indices.empty?

    indices.each { |index| FileUtils.touch guard_file(index) }
    exception = nil
    begin
      super(*(indices + [options]))
    rescue Riddle::IndexerError => e
      # Hold the exception
      exception = e
    end
    indices.each { |index| FileUtils.rm guard_file(index) }
    handle_index_errors = ThinkingSphinx::Configuration.instance.on_indexer_error.to_s
    if handle_index_errors == 'raise_error'
      raise exception if exception.present?
    elsif handle_index_errors == 'log'
      puts "Thinking Sphinx Indexer Failure: #{exception.message.to_s}"
    else
      # Swallow
    end
  end

  def guard_file(index)
    File.join(
      ThinkingSphinx::Configuration.instance.indices_location,
      "ts-#{index}.tmp"
    )
  end
end
