class ThinkingSphinx::Deltas::IndexJob
  def initialize(indices)
    @indices = indices
  end

  def perform
    rotate = ThinkingSphinx.sphinx_running? ? "--rotate" : ""

    output = `#{configuration.bin_path}#{configuration.indexer_binary_name} --config "#{configuration.config_file}" #{rotate} #{@indices.join(' ')}`
    puts(output) unless ThinkingSphinx.suppress_delta_output?

    ThinkingSphinx::Connection.pool.clear

    true
  end

  def configuration
    ThinkingSphinx::Configuration.instance
  end
end
