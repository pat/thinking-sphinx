namespace :ts do
  desc 'Generate the Sphinx configuration file'
  task :configure => :environment do
    interface.configure
  end

  desc 'Generate the Sphinx configuration file and process all indices'
  task :index => :environment do
    interface.index(
      ENV['INDEX_ONLY'] != 'true',
      !Rake.application.options.silent
    )
  end

  desc 'Clear out Sphinx files'
  task :clear => :environment do
    interface.clear
  end

  desc 'Generate fresh index files for real-time indices'
  task :generate => :environment do
    interface.prepare
    interface.generate
  end

  desc 'Stop Sphinx, index and then restart Sphinx'
  task :rebuild => [:stop, :clear, :index, :start]

  desc 'Stop Sphinx, clear files, reconfigure, start Sphinx, generate files'
  task :regenerate => [:stop, :clear, :configure, :start, :generate]

  desc 'Restart the Sphinx daemon'
  task :restart => [:stop, :start]

  desc 'Start the Sphinx daemon'
  task :start => :environment do
    interface.start
  end

  desc 'Stop the Sphinx daemon'
  task :stop => :environment do
    interface.stop
  end

  desc 'Determine whether Sphinx is running'
  task :status => :environment do
    interface.status
  end

  def interface
    @interface ||= ThinkingSphinx::RakeInterface.new
  end
end
