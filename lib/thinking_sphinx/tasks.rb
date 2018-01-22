# frozen_string_literal: true

namespace :ts do
  desc 'Generate the Sphinx configuration file'
  task :configure => :environment do
    interface.configure
  end

  desc 'Generate the Sphinx configuration file and process all indices'
  task :index => ['ts:sql:index', 'ts:rt:index']

  desc 'Clear out Sphinx files'
  task :clear => ['ts:sql:clear', 'ts:rt:clear']

  desc "Merge all delta indices into their respective core indices"
  task :merge => ["ts:sql:merge"]

  desc 'Delete and regenerate Sphinx files, restart the daemon'
  task :rebuild => [
    :stop, :clear, :configure, 'ts:sql:index', :start, 'ts:rt:index'
  ]

  desc 'Restart the Sphinx daemon'
  task :restart => [:stop, :start]

  desc 'Start the Sphinx daemon'
  task :start => :environment do
    interface.daemon.start
  end

  desc 'Stop the Sphinx daemon'
  task :stop => :environment do
    interface.daemon.stop
  end

  desc 'Determine whether Sphinx is running'
  task :status => :environment do
    interface.daemon.status
  end

  namespace :sql do
    desc 'Delete SQL-backed Sphinx files'
    task :clear => :environment do
      interface.sql.clear
    end

    desc 'Generate fresh index files for SQL-backed indices'
    task :index => :environment do
      interface.sql.index(ENV['INDEX_ONLY'] != 'true')
    end

    task :merge => :environment do
      interface.sql.merge
    end

    desc 'Delete and regenerate SQL-backed Sphinx files, restart the daemon'
    task :rebuild => ['ts:stop', 'ts:sql:clear', 'ts:sql:index', 'ts:start']
  end

  namespace :rt do
    desc 'Delete real-time Sphinx files'
    task :clear => :environment do
      interface.rt.clear
    end

    desc 'Generate fresh index files for real-time indices'
    task :index => :environment do
      interface.rt.index
    end

    desc 'Delete and regenerate real-time Sphinx files, restart the daemon'
    task :rebuild => [
      'ts:stop', 'ts:rt:clear', 'ts:configure', 'ts:start', 'ts:rt:index'
    ]
  end

  def interface
    @interface ||= ThinkingSphinx.rake_interface.new(
      :verbose     => Rake::FileUtilsExt.verbose_flag,
      :silent      => Rake.application.options.silent,
      :nodetach    => (ENV['NODETACH'] == 'true'),
      :index_names => ENV.fetch('INDEX_FILTER', '').split(',')
    )
  end
end
