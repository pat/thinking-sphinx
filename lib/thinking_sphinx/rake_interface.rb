class ThinkingSphinx::RakeInterface
  def clear_all
    [
      configuration.indices_location,
      configuration.searchd.binlog_path
    ].each do |path|
      FileUtils.rm_r(path) if File.exists?(path)
    end
  end

  def clear_real_time
    configuration.preload_indices
    indices = configuration.indices.select { |index| index.type == 'rt' }
    indices.each do |index|
      index.render
      Dir["#{index.path}.*"].each { |path| FileUtils.rm path }
    end

    path = configuration.searchd.binlog_path
    FileUtils.rm_r(path) if File.exists?(path)
  end

  def configure
    puts "Generating configuration to #{configuration.configuration_file}"
    configuration.render_to_file
  end

  def generate
    indices = configuration.indices.select { |index| index.type == 'rt' }
    indices.each do |index|
      ThinkingSphinx::RealTime::Populator.populate index
    end
  end

  def index(reconfigure = true, verbose = true)
    configure if reconfigure
    FileUtils.mkdir_p configuration.indices_location
    ThinkingSphinx.before_index_hooks.each { |hook| hook.call }
    controller.index :verbose => verbose
  rescue Riddle::CommandFailedError => error
    handle_command_failure 'indexing', error.command_result
  end

  def prepare
    configuration.preload_indices
    configuration.render

    FileUtils.mkdir_p configuration.indices_location
  end

  def start(options={})
    if running?
      raise ThinkingSphinx::SphinxAlreadyRunning, 'searchd is already running'
    end

    FileUtils.mkdir_p configuration.indices_location

    options[:nodetach] ? start_attached(options) : start_detached(options)
  end

  def status
    if running?
      puts "The Sphinx daemon searchd is currently running."
    else
      puts "The Sphinx daemon searchd is not currently running."
    end
  end

  def stop
    unless running?
      puts 'searchd is not currently running.' and return
    end

    pid = controller.pid
    until controller.stop do
      sleep(0.5)
    end

    puts "Stopped searchd daemon (pid: #{pid})."
  rescue Riddle::CommandFailedError => error
    handle_command_failure 'stop', error.command_result
  end

  private

  delegate :controller, :to => :configuration
  delegate :running?,   :to => :controller

  def command_output(output)
    return "See above\n" if output.nil?

    "\n\t" + output.gsub("\n", "\n\t")
  end

  def configuration
    ThinkingSphinx::Configuration.instance
  end

  def handle_command_failure(type, result)
    puts <<-TXT

The Sphinx #{type} command failed:
  Command: #{result.command}
  Status:  #{result.status}
  Output:  #{command_output result.output}
There may be more information about the failure in #{configuration.searchd.log}.
    TXT
    exit result.status
  end

  def start_attached(options)
    unless pid = fork
      controller.start(options)
    end

    Signal.trap('TERM') { Process.kill(:TERM, pid); }
    Signal.trap('INT')  { Process.kill(:TERM, pid); }
    Process.wait(pid)
  end

  def start_detached(options)
    result = controller.start options

    if running?
      puts "Started searchd successfully (pid: #{controller.pid})."
    else
      handle_command_failure 'start', result
    end
  rescue Riddle::CommandFailedError => error
    handle_command_failure 'start', error.command_result
  end
end
