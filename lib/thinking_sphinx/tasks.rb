require 'fileutils'

namespace :thinking_sphinx do
  task :app_env do
    if defined?(RAILS_ROOT)
      Rake::Task[:environment].invoke
      Rails.configuration.cache_classes = false
    end
    
    Rake::Task[:merb_env].invoke    if defined?(Merb)
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

    system! "#{config.bin_path}#{config.searchd_binary_name} --pidfile --config \"#{config.config_file}\""
    
    sleep(2)
    
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
      system! "#{config.bin_path}#{config.searchd_binary_name} --stop --config \"#{config.config_file}\""
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
    ThinkingSphinx::Deltas::Job.cancel_thinking_sphinx_jobs
    
    config = ThinkingSphinx::Configuration.instance
    unless ENV["INDEX_ONLY"] == "true"
      puts "Generating Configuration to #{config.config_file}"
      config.build
    end
        
    FileUtils.mkdir_p config.searchd_file_path
    cmd = "#{config.bin_path}#{config.indexer_binary_name} --config \"#{config.config_file}\" --all"
    cmd << " --rotate" if sphinx_running?
    
    system! cmd
  end
  
  desc "Stop Sphinx (if it's running), rebuild the indexes, and start Sphinx"
  task :rebuild => :app_env do
    Rake::Task["thinking_sphinx:stop"].invoke if sphinx_running?
    Rake::Task["thinking_sphinx:index"].invoke
    Rake::Task["thinking_sphinx:start"].invoke
  end
  
  namespace :index do
    task :delta => :app_env do
      ThinkingSphinx.indexed_models.select { |model|
        model.constantize.sphinx_indexes.any? { |index| index.delta? }
      }.each do |model|
        model.constantize.sphinx_indexes.select { |index|
          index.delta? && index.delta_object.respond_to?(:delayed_index)
        }.each { |index|
          index.delta_object.delayed_index(index.model)
        }
      end
    end
  end
  
  desc "Process stored delta index requests"
  task :delayed_delta => :app_env do
    require 'delayed/worker'
    
    Delayed::Worker.new(
      :min_priority => ENV['MIN_PRIORITY'],
      :max_priority => ENV['MAX_PRIORITY']
    ).start
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
  namespace :in do
    desc "Index Thinking Sphinx datetime delta indexes"
    task :delta => "thinking_sphinx:index:delta"
  end
  task :index   => "thinking_sphinx:index"
  desc "Restart Sphinx"
  task :restart => "thinking_sphinx:restart"
  desc "Generate the Sphinx configuration file using Thinking Sphinx's settings"
  task :conf    => "thinking_sphinx:configure"
  desc "Generate the Sphinx configuration file using Thinking Sphinx's settings"
  task :config  => "thinking_sphinx:configure"
  desc "Stop Sphinx (if it's running), rebuild the indexes, and start Sphinx"
  task :rebuild => "thinking_sphinx:rebuild"
  desc "Process stored delta index requests"
  task :dd      => "thinking_sphinx:delayed_delta"
end

def sphinx_pid
  ThinkingSphinx.sphinx_pid
end

def sphinx_running?
  ThinkingSphinx.sphinx_running?
end

# a fail-fast, hopefully helpful version of system
def system!(cmd)
  unless system(cmd)
    raise <<-SYSTEM_CALL_FAILED
The following command failed:
  #{cmd}

This could be caused by a PATH issue in the environment of cron/passenger/etc. Your current PATH:
  #{ENV['PATH']}
You can set the path to your indexer and searchd binaries using the bin_path property in config/sphinx.yml:
  production:
    bin_path: '/usr/local/bin'
SYSTEM_CALL_FAILED
  end
end
