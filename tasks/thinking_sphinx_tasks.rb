require 'fileutils'

namespace :thinking_sphinx do
  task :app_env do
    Rake::Task[:environment].invoke if defined?(RAILS_ROOT)
    Rake::Task[:merb_env].invoke    if defined?(Merb)
  end
  
  desc "Start a Sphinx searchd daemon using Thinking Sphinx's settings"
  task :start => :app_env do
    config = ThinkingSphinx::Configuration.new
    
    FileUtils.mkdir_p config.searchd_file_path
    raise RuntimeError, "searchd is already running." if sphinx_running?
    
    Dir["#{config.searchd_file_path}/*.spl"].each { |file| File.delete(file) }
    
    cmd = "searchd --config #{config.config_file}"
    puts cmd
    system cmd
    
    sleep(2)
    
    if sphinx_running?
      puts "Started successfully (pid #{sphinx_pid})."
    else
      puts "Failed to start searchd daemon. Check #{config.searchd_log_file}."
    end
  end
  
  desc "Stop Sphinx using Thinking Sphinx's settings"
  task :stop => :app_env do
    raise RuntimeError, "searchd is not running." unless sphinx_running?
    pid = sphinx_pid
    system "kill #{pid}"
    puts "Stopped search daemon (pid #{pid})."
  end
  
  desc "Restart Sphinx"
  task :restart => [:app_env, :stop, :start]
  
  desc "Generate the Sphinx configuration file using Thinking Sphinx's settings"
  task :configure => :app_env do
    ThinkingSphinx::Configuration.new.build
  end
  
  desc "Index data for Sphinx using Thinking Sphinx's settings"
  task :index => [:check_for_indexer, :app_env, :configure] do
    config = ThinkingSphinx::Configuration.new
    
    FileUtils.mkdir_p config.searchd_file_path
    cmd = "indexer --config #{config.config_file} --all"
    cmd << " --rotate" if sphinx_running?
    puts cmd
    system cmd
    
    check_rotate if sphinx_running?
  end
  
  desc "Reindex the passed delta"
  task :index_delta => [:check_for_indexer, :app_env, :configure] do
    config = ThinkingSphinx::Configuration.new
    
    index_name = get_index_name(ENV['MODEL'])

    cmd = "indexer --config '#{config.config_file}'"
    cmd << " --rotate" if sphinx_running?
    cmd << " #{index_name}_delta"
    puts cmd
    system cmd
    
    check_rotate if sphinx_running?
  end
    
  desc "Merge the passed indexes delta into the core"
  task :index_merge => [:check_for_indexer, :app_env, :configure] do
    config = ThinkingSphinx::Configuration.new
    
    index_name = get_index_name(ENV['MODEL'])

    cmd = "indexer --config '#{config.config_file}'"
    cmd << " --rotate" if sphinx_running?
    cmd << " --merge #{index_name}_core #{index_name}_delta --merge-dst-range deleted 0 0"
    puts cmd
    system cmd
    
    check_rotate if sphinx_running?
  end
  
  desc "Checks to see if the indexer is already running"
  task :check_for_indexer do
    ps_check = `ps aux | grep -v 'grep' | grep indexer`.split(/\n/)
    raise RuntimeError, "Indexer is already running:\n\n #{ps_check.join('\n')}" if ps_check.size > 0
  end
end

namespace :ts do
  desc "Start a Sphinx searchd daemon using Thinking Sphinx's settings"
  task :start   => "thinking_sphinx:start"
  desc "Stop Sphinx using Thinking Sphinx's settings"
  task :stop    => "thinking_sphinx:stop"
  desc "Index data for Sphinx using Thinking Sphinx's settings"
  task :in      => "thinking_sphinx:index"
  desc "Index data for Sphinx using Thinking Sphinx's settings"
  task :index   => "thinking_sphinx:index"
  desc "Restart Sphinx"
  task :restart => "thinking_sphinx:restart"
  desc "Generate the Sphinx configuration file using Thinking Sphinx's settings"
  task :config  => "thinking_sphinx:configure"
end

def sphinx_pid
  config = ThinkingSphinx::Configuration.new
  
  if File.exists?(config.pid_file)
    `cat #{config.pid_file}`[/\d+/]
  else
    nil
  end
end

def sphinx_running?
  sphinx_pid && `ps -p #{sphinx_pid} | wc -l`.to_i > 1
end

def get_index_name(str)
  raise "You must pass a model name!" if str.to_s.strip.blank?
  klass = str.to_s.strip.classify.constantize
  raise "The class '#{klass}' has no Thinking Sphinx indexes defined" if !klass.indexes || klass.indexes.empty?
  klass.indexes.first.name    
end

def check_rotate
  sleep(5)
  config = ThinkingSphinx::Configuration.new
  
  failed = Dir[config.searchd_file_path + "/*.new.*"]
  if failed.any?
    # puts "warning; indexes failed to rotate! Deleting new indexes"
    # puts "try 'killall searchd' and then 'rake thinking_sphinx:start'"
    # failed.each {|f| File.delete f }
    puts "Problem rotating indexes!"
    puts "Look in #{config.searchd_file_path} for files with 'new' in them - they shouldn't be there!  You may need to reindex."
  else
    puts "The indexes rotated ok"
  end
end