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
      `#{indexer} 2>&1`[/^Sphinx (\d+\.\d+(\.\d+|(\-id64)?\-beta))/, 1]
    rescue
      nil
    end
    
    def index(*indexes)
      options = indexes.last.is_a?(Hash) ? indexes.pop : {}
      indexes << '--all' if indexes.empty?
      
      cmd = "#{indexer} --config \"#{@path}\" #{indexes.join(' ')}"
      cmd << " --rotate" if running?
      options[:verbose] ? system(cmd) : `#{cmd}`
    end
    
    def start
      return if running?
      
      cmd = "#{searchd} --pidfile --config \"#{@path}\""
      
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
      return true unless running?
      
      stop_flag = 'stopwait'
      stop_flag = 'stop' if Riddle.loaded_version.split('.').first == '0'
      cmd = %(#{searchd} --pidfile --config "#{@path}" --#{stop_flag})
      
      if RUBY_PLATFORM =~ /mswin/
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
  end
end
