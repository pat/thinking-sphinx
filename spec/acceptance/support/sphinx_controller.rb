# frozen_string_literal: true

class SphinxController
  def initialize
    config.searchd.mysql41 = 9307
  end

  def setup
    FileUtils.mkdir_p config.indices_location
    config.controller.bin_path = ENV['SPHINX_BIN'] || ''
    config.render_to_file && index

    ThinkingSphinx::Configuration.reset

    ActiveSupport::Dependencies.loaded.each do |path|
      $LOADED_FEATURES.delete "#{path}.rb"
    end

    ActiveSupport::Dependencies.clear

    config.searchd.mysql41 = 9307
    config.settings['quiet_deltas']      = true
    config.settings['attribute_updates'] = true
    config.controller.bin_path           = ENV['SPHINX_BIN'] || ''
  end

  def start
    config.controller.start
  rescue Riddle::CommandFailedError => error
    puts <<-TXT

The Sphinx start command failed:
  Command: #{error.command_result.command}
  Status:  #{error.command_result.status}
  Output:  #{error.command_result.output}
    TXT
    raise error
  end

  def stop
    while config.controller.running? do
      config.controller.stop
      sleep(0.1)
    end
  end

  def index(*indices)
    ThinkingSphinx::Commander.call :index_sql, config, :indices => indices
  end

  def merge
    ThinkingSphinx::Commander.call(:merge_and_update, config, {})
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end
end
