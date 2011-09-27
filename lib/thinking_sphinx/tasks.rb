namespace :ts do
  task :version do
    puts "Thinking Sphinx v#{ThinkingSphinx::VERSION}"
  end

  task :configure => :environment do
    interface.configure
  end

  task :index => :environment do
    interface.index
  end

  task :rebuild => [:stop, :index, :start]
  task :restart => [:stop, :start]

  task :start => :environment do
    interface.start
  end

  task :stop => :environment do
    interface.stop
  end

  def interface
    @interface ||= ThinkingSphinx::RakeInterface.new
  end
end
