class ThinkingSphinx::Interfaces::SQL
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

    FileUtils.rm_r Dir["#{configuration.indices_location}/ts-*.tmp"]
  end

  def index(reconfigure = true, verbose = nil)
    stream.puts <<-TXT unless verbose.nil?
The verbose argument to the index method is now deprecated, and can instead be
managed by the :verbose option passed in when initialising RakeInterface. That
option is set automatically when invoked by rake, via rake's --silent and/or
--quiet arguments.
    TXT
    return if indices.empty?

    ThinkingSphinx::Commands::Configure.call configuration, options if reconfigure
    ThinkingSphinx.before_index_hooks.each { |hook| hook.call }

    ThinkingSphinx::Commands::Index.call configuration, options, stream
  end

  private

  def indices
    @indices ||= configuration.indices.select do |index|
      index.type == 'plain' || index.type.blank?
    end
  end
end
