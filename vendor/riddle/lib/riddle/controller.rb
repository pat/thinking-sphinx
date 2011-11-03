module Riddle
  class Controller
    attr_accessor :path, :bin_path, :searchd_binary_name, :indexer_binary_name

    def initialize(configuration, path)
      @configuration  = configuration
      @path           = path

      @bin_path            = ''
      @searchd_binary_name = 'searchd'
      @indexer_binary_name = 'indexer'
    end

    def sphinx_version
      `#{indexer} 2>&1`[/Sphinx (\d+\.\d+(\.\d+|(?:-dev|(\-id64)?\-beta)))/, 1]
    rescue
      nil
    end

    def index(*indices)
      options = indices.last.is_a?(Hash) ? indices.pop : {}
      indices << '--all' if indices.empty?

      cmd = "#{indexer} --config \"#{@path}\" #{indices.join(' ')}"
      cmd << " --rotate" if running?
      options[:verbose] ? system(cmd) : `#{cmd}`
    end

    def start(options={})
      return if running?
      check_for_configuration_file

      cmd = "#{searchd} --pidfile --config \"#{@path}\""
      cmd << " --nodetach" if options[:nodetach]

      if options[:nodetach]
        exec(cmd)
      elsif RUBY_PLATFORM =~ /mswin|mingw/
        system("start /B #{cmd} 1> NUL 2>&1")
      else
        `#{cmd}`
      end

      sleep(1)

      unless running?
        puts "Failed to start searchd daemon. Check #{@configuration.searchd.log}."
      end
    end

    def stop
      return true unless running?
      check_for_configuration_file

      stop_flag = 'stopwait'
      stop_flag = 'stop' if Riddle.loaded_version.split('.').first == '0'
      cmd = %(#{searchd} --pidfile --config "#{@path}" --#{stop_flag})

      if RUBY_PLATFORM =~ /mswin|mingw/
        system("start /B #{cmd} 1> NUL 2>&1")
      else
        `#{cmd}`
      end
    ensure
      return !running?
    end

    def pid
      if File.exists?(@configuration.searchd.pid_file)
        File.read(@configuration.searchd.pid_file)[/\d+/]
      else
        nil
      end
    end

    def running?
      !!pid && !!Process.kill(0, pid.to_i)
    rescue
      false
    end

    private

    def indexer
      "#{bin_path}#{indexer_binary_name}"
    end

    def searchd
      "#{bin_path}#{searchd_binary_name}"
    end

    def check_for_configuration_file
      return if File.exist?(@path)
      raise "Configuration file '#{@path}' does not exist"
    end
  end
end
