require 'fileutils'
require 'timeout'

namespace :thinking_sphinx do
  task :app_env do
    if defined?(RAILS_ROOT)
      Rake::Task[:environment].invoke
      if defined?(Rails.configuration)
        Rails.configuration.cache_classes = false
      else
        Rails::Initializer.run { |config| config.cache_classes = false }
      end
    elsif defined?(Merb)
      Rake::Task[:merb_env].invoke
    elsif defined?(Sinatra)
      Sinatra::Application.environment = ENV['RACK_ENV']
    end
  end
  
  desc "Output the current Thinking Sphinx version"
  task :version => :app_env do
    puts "Thinking Sphinx v" + ThinkingSphinx.version
  end
  
  desc "Stop if running, then start a Sphinx searchd daemon using Thinking Sphinx's settings"
  task :running_start => :app_env do
    Rake::Task["thinking_sphinx:stop"].invoke if sphinx_running?
    Rake::Task["thinking_sphinx:start"].invoke
  end
  
  desc "Start a Sphinx searchd daemon using Thinking Sphinx's settings"
  task :start => :app_env do
    config = ThinkingSphinx::Configuration.instance
    
    FileUtils.mkdir_p config.searchd_file_path
    raise RuntimeError, "searchd is already running." if sphinx_running?
    
    Dir["#{config.searchd_file_path}/*.spl"].each { |file| File.delete(file) }
    
    config.controller.start
    
    if sphinx_running?
      puts "Started successfully (pid #{sphinx_pid})."
    else
      puts "Failed to start searchd daemon. Check #{config.searchd_log_file}"
    end
  end
  
  desc "Stop Sphinx using Thinking Sphinx's settings"
  task :stop => :app_env do
    unless sphinx_running?
      puts "searchd is not running"
    else
      config = ThinkingSphinx::Configuration.instance
      pid    = sphinx_pid
      config.controller.stop
      
      # Ensure searchd is stopped, but don't try too hard
      Timeout.timeout(5) do
        sleep(1) until config.controller.stop
      end
      
      puts "Stopped search daemon (pid #{pid})."
    end
  end
  
  desc "Restart Sphinx"
  task :restart => [:app_env, :stop, :start]
  
  desc "Generate the Sphinx configuration file using Thinking Sphinx's settings"
  task :configure => :app_env do
    config = ThinkingSphinx::Configuration.instance
    puts "Generating Configuration to #{config.config_file}"
    config.build
  end
  
  desc "Index data for Sphinx using Thinking Sphinx's settings"
  task :index => :app_env do
    config = ThinkingSphinx::Configuration.instance
    unless ENV["INDEX_ONLY"] == "true"
      puts "Generating Configuration to #{config.config_file}"
      config.build
    end
    
    FileUtils.mkdir_p config.searchd_file_path
    config.controller.index :verbose => true
  end
  
  desc "Reindex Sphinx without regenerating the configuration file"
  task :reindex => :app_env do
    config = ThinkingSphinx::Configuration.instance
    FileUtils.mkdir_p config.searchd_file_path
    output = config.controller.index
    puts output
    config.touch_reindex_file(output)
  end
  
  desc "Stop Sphinx (if it's running), rebuild the indexes, and start Sphinx"
  task :rebuild => :app_env do
    Rake::Task["thinking_sphinx:stop"].invoke if sphinx_running?
    Rake::Task["thinking_sphinx:index"].invoke
    Rake::Task["thinking_sphinx:start"].invoke
  end
end

namespace :ts do
  desc "Output the current Thinking Sphinx version"
  task :version => "thinking_sphinx:version"
  desc "Stop if running, then start a Sphinx searchd daemon using Thinking Sphinx's settings"
  task :run     => "thinking_sphinx:running_start"
  desc "Start a Sphinx searchd daemon using Thinking Sphinx's settings"
  task :start   => "thinking_sphinx:start"
  desc "Stop Sphinx using Thinking Sphinx's settings"
  task :stop    => "thinking_sphinx:stop"
  desc "Index data for Sphinx using Thinking Sphinx's settings"
  task :in      => "thinking_sphinx:index"
  task :index   => "thinking_sphinx:index"
  desc "Reindex Sphinx without regenerating the configuration file"
  task :reindex => "thinking_sphinx:reindex"
  desc "Restart Sphinx"
  task :restart => "thinking_sphinx:restart"
  desc "Generate the Sphinx configuration file using Thinking Sphinx's settings"
  task :conf    => "thinking_sphinx:configure"
  desc "Generate the Sphinx configuration file using Thinking Sphinx's settings"
  task :config  => "thinking_sphinx:configure"
  desc "Stop Sphinx (if it's running), rebuild the indexes, and start Sphinx"
  task :rebuild => "thinking_sphinx:rebuild"
end

def sphinx_pid
  ThinkingSphinx.sphinx_pid
end

def sphinx_running?
  ThinkingSphinx.sphinx_running?
end
