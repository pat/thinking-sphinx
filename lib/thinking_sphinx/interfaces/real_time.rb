class ThinkingSphinx::Interfaces::RealTime
  include ThinkingSphinx::WithOutput

  def initialize(configuration, options, stream = STDOUT)
    super

    configuration.preload_indices

    FileUtils.mkdir_p configuration.indices_location
  end

  def clear
    indices.each do |index|
      index.render
      Dir["#{index.path}.*"].each { |path| FileUtils.rm path }
    end

    path = configuration.searchd.binlog_path
    FileUtils.rm_r(path) if File.exists?(path)
  end

  def index
    return if indices.empty? || !configuration.controller.running?

    indices.each { |index| ThinkingSphinx::RealTime::Populator.populate index }
  end

  private

  def indices
    @indices ||= begin
      indices = configuration.indices.select { |index| index.type == 'rt' }

      if options[:index_filter]
        indices.select! { |index| index.name == options[:index_filter] }
      end

      indices
    end
  end
end
