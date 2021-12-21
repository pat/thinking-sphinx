# frozen_string_literal: true

class ThinkingSphinx::Test
  def self.init(suppress_delta_output = true)
    FileUtils.mkdir_p config.indices_location
    config.settings['quiet_deltas'] = suppress_delta_output
  end

  def self.start(options = {})
    config.render_to_file
    config.controller.index if options[:index].nil? || options[:index]
    config.controller.start
  end

  def self.start_with_autostop
    autostop
    start
  end

  def self.stop
    config.controller.stop
    sleep(0.5) # Ensure Sphinx has shut down completely
  end

  def self.autostop
    Kernel.at_exit do
      ThinkingSphinx::Test.stop
    end
  end

  def self.run(&block)
    begin
      start
      yield
    ensure
      stop
    end
  end

  def self.clear
    [
      config.indices_location,
      config.searchd.binlog_path
    ].each do |path|
      FileUtils.rm_r(path) if File.exist?(path)
    end
  end

  def self.config
    @config ||= ::ThinkingSphinx::Configuration.instance
  end

  def self.index(*indexes)
    config.controller.index *indexes
  end
end
