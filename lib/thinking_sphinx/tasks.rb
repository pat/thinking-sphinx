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

  desc 'DEPRECATED: Clear out real-time index files'
  task :clear_rt => :environment do
    puts <<-TXT
The ts:clear_rt task is now deprecated due to the unified task approach, and
invokes ts:rt:clear.
* To delete all indices (both SQL-backed and real-time), use ts:clear.
* To delete just real-time indices, use ts:rt:clear.
* To delete just SQL-backed indices, use ts:sql:clear.

    TXT

    Rake::Task['ts:rt:clear'].invoke
  end

  desc 'DEPRECATED: Generate fresh index files for all indices'
  task :generate => :environment do
    puts <<-TXT
The ts:generate task is now deprecated due to the unified task approach, and
invokes ts:index.
* To process all indices (both SQL-backed and real-time), use ts:index.
* To process just real-time indices, use ts:rt:index.
* To process just SQL-backed indices, use ts:sql:index.

    TXT

    Rake::Task['ts:index'].invoke
  end

  desc 'Delete and regenerate Sphinx files, restart the daemon'
  task :rebuild => [
    :stop, :clear, :configure, 'ts:sql:index', :start, 'ts:rt:index'
  ]

  desc 'DEPRECATED: Delete and regenerate Sphinx files, restart the daemon'
  task :regenerate do
        puts <<-TXT
The ts:regenerate task is now deprecated due to the unified task approach, and
invokes ts:rebuild.
* To rebuild all indices (both SQL-backed and real-time), use ts:rebuild.
* To rebuild just real-time indices, use ts:rt:rebuild.
* To rebuild just SQL-backed indices, use ts:sql:rebuild.

    TXT

    Rake::Task['ts:rebuild'].invoke
  end

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
    @interface ||= ThinkingSphinx::RakeInterface.new(
      :verbose      => Rake::FileUtilsExt.verbose_flag,
      :silent       => Rake.application.options.silent,
      :nodetach     => (ENV['NODETACH'] == 'true'),
      :index_filter => ENV['INDEX_FILTER']
    )
  end
end
