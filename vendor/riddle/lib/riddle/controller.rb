module Riddle
  class Controller
    def initialize(configuration, path)
      @configuration  = configuration
      @path           = path
    end

    def index
      cmd = "indexer --config #{@path} --all"
      cmd << " --rotate" if running?
      `#{cmd}`
    end

    def start
      return if running?

      cmd = "searchd --pidfile --config #{@path}"

      if RUBY_PLATFORM =~ /mswin/
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
      return unless running?
      Process.kill('SIGTERM', pid.to_i)
    rescue Errno::EINVAL
      Process.kill('SIGKILL', pid.to_i)
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

  end
end