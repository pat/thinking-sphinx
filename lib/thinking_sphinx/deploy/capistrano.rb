Capistrano::Configuration.instance(:must_exist).load do
  namespace :thinking_sphinx do
    namespace :install do
      desc <<-DESC
        Install Sphinx by source
        
        If Postgres is available, Sphinx will use it.
        
        If the variable :thinking_sphinx_configure_args is set, it will
        be passed to the Sphinx configure script. You can use this to
        install Sphinx in a non-standard location:
        
          set :thinking_sphinx_configure_args, "--prefix=$HOME/software"
DESC

      task :sphinx do
        with_postgres = false
        begin
          run "which pg_config" do |channel, stream, data|
            with_postgres = !(data.nil? || data == "")
          end
        rescue Capistrano::CommandError => e
          puts "Continuing despite error: #{e.message}"
        end
      
        args = []
        if with_postgres
          run "pg_config --pkgincludedir" do |channel, stream, data|
            args << "--with-pgsql=#{data}"
          end
        end
        args << fetch(:thinking_sphinx_configure_args, '')
        
        commands = <<-CMD
        wget -q http://www.sphinxsearch.com/downloads/sphinx-0.9.8.1.tar.gz >> sphinx.log
        tar xzvf sphinx-0.9.8.1.tar.gz
        cd sphinx-0.9.8.1
        ./configure #{args.join(" ")}
        make
        #{try_sudo} make install
        rm -rf sphinx-0.9.8.1 sphinx-0.9.8.1.tar.gz
        CMD
        run commands.split(/\n\s+/).join(" && ")
      end
    
      desc "Install Thinking Sphinx as a gem from GitHub"
      task :ts do
        run "#{try_sudo} gem install thinking-sphinx --source http://gemcutter.org"
      end
    end
  
    desc "Generate the Sphinx configuration file"
    task :configure do
      rake "thinking_sphinx:configure"
    end
  
    desc "Index data"
    task :index do
      rake "thinking_sphinx:index"
    end
  
    desc "Start the Sphinx daemon"
    task :start do
      configure
      rake "thinking_sphinx:start"
    end
  
    desc "Stop the Sphinx daemon"
    task :stop do
      configure
      rake "thinking_sphinx:stop"
    end
  
    desc "Stop and then start the Sphinx daemon"
    task :restart do
      stop
      start
    end
  
    desc "Stop, re-index and then start the Sphinx daemon"
    task :rebuild do
      stop
      index
      start
    end
  
    desc "Add the shared folder for sphinx files for the production environment"
    task :shared_sphinx_folder, :roles => :web do
      run "mkdir -p #{shared_path}/db/sphinx/production"
    end

    def rake(*tasks)
      rails_env = fetch(:rails_env, "production")
      rake = fetch(:rake, "rake")
      tasks.each do |t|
        run "cd #{current_path}; #{rake} RAILS_ENV=#{rails_env} #{t}"
      end
    end
  end
end
