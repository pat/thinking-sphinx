class ThinkingSphinx::Test
  def self.init(suppress_delta_output = true)
    set_flags suppress_delta_output
    create_indexes_folder
  end
  
  def self.start
    config.build
    config.controller.index
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
    start
    yield
    stop
  end
  
  def self.config
    @config ||= ::ThinkingSphinx::Configuration.instance
  end
  
  def self.index(*indexes)
    config.controller.index *indexes
  end
  
  def self.set_flags(suppress_delta_output)
    ::ThinkingSphinx.deltas_enabled        = true
    ::ThinkingSphinx.updates_enabled       = true
    ::ThinkingSphinx.suppress_delta_output = suppress_delta_output
  end
  
  def self.create_indexes_folder
    FileUtils.mkdir_p config.searchd_file_path
  end
end
