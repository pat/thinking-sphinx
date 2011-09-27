class ThinkingSphinx::RakeInterface
  def configure
    puts "Generating configuration to #{config.configuration_file}"
    config.render_to_file
  end

  def index
    configure
    FileUtils.mkdir_p config.indices_location
    controller.index :verbose => true
  end

  def start
    raise RuntimeError, 'searchd is already running' if controller.running?

    controller.start

    if controller.running?
      puts "Started searchd successfully (pid: #{controller.pid})."
    else
      puts "Failed to start searchd. Check the log files for more information."
    end
  end

  def stop
    unless controller.running?
      puts 'searchd is not currently running.' and return
    end

    pid = controller.pid
    until controller.stop do
      sleep(0.5)
    end

    puts "Stopped searchd daemon (pid: #{pid})."
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end

  def controller
    config.controller
  end
end
