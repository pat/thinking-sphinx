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
      `#{cmd}`

      sleep(1)

      unless running?
        puts "Failed to start searchd daemon. Check #{@configuration.searchd.log}."
      end
    end

    def stop
      return unless running?
      Process.kill('SIGTERM', pid)
    rescue Errno::EINVAL
      Process.kill('SIGKILL', pid)
    end

    def pid
      if File.exists?(@configuration.searchd.pid_file)
        File.read(@configuration.searchd.pid_file)[/\d+/]
      else
        nil
      end
    end

    def running?
      !!pid && !!Process.kill(0, pid)
    rescue
      false
    end

  end
end