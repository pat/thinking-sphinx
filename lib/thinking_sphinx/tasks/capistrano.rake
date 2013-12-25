namespace :load do
  task :defaults do
    set :thinking_sphinx_roles, :db
  end
end

namespace :thinking_sphinx do
  desc <<-DESC
Stop, reindex, and then start the Sphinx search daemon. This task must be executed \
if you alter the structure of your indexes.
  DESC
  task :rebuild do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:stage) do
          execute :rake, "ts:rebuild"
        end
      end
    end
  end
  after :rebuild, 'thinking_sphinx:symlink_indexes'

  desc 'Build Sphinx indexes into the shared path and symlink them into your release.'
  task :index do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:stage) do
          execute :rake, 'ts:index'
        end
      end
    end
  end
  after :index, 'thinking_sphinx:symlink_indexes'

  desc 'Symlink Sphinx indexes from the shared folder to the latest release.'
  task :symlink_indexes do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        execute :ln, "-nfs #{shared_path}/db/sphinx db/"
      end
    end
  end
  after 'deploy:finishing', 'thinking_sphinx:symlink_indexes'

  desc 'Restart the Sphinx search daemon.'
  task :restart do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:stage) do
          %w(stop configure start).each do |task|
            execute :rake, "ts:#{task}"
          end
        end
      end
    end
  end

  desc 'Start the Sphinx search daemon.'
  task :start do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:stage) do
          execute :rake, 'ts:start'
        end
      end
    end
  end
  before :start, 'thinking_sphinx:configure'

  desc 'Generate the Sphinx configuration file.'
  task :configure do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:stage) do
          execute :rake, 'ts:configure'
        end
      end
    end
  end

  desc 'Stop the Sphinx search daemon.'
  task :stop do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:stage) do
          execute :rake, 'ts:stop'
        end
      end
    end
  end

  desc 'Create the shared folder for sphinx indexes.'
  task :shared_sphinx_folder do
    on roles fetch(:thinking_sphinx_roles) do
      within shared_path do
        execute :mkdir, "-p db/sphinx/#{fetch(:stage)}"
      end
    end
  end
  after 'deploy:check', 'thinking_sphinx:shared_sphinx_folder'
end
