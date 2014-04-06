namespace :load do
  task :defaults do
    set :thinking_sphinx_roles, :db
    set :thinking_spinx_rails_env, -> { fetch(:stage) }
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
        with rails_env: fetch(:thinking_spinx_rails_env) do
          execute :rake, "ts:rebuild"
        end
      end
    end
  end

  desc 'Stop Sphinx, clear Sphinx index files, generate configuration file, start Sphinx, repopulate all data.'
  task :regenerate do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:thinking_spinx_rails_env) do
          execute :rake, 'ts:regenerate'
        end
      end
    end
  end

  desc 'Build Sphinx indexes into the shared path.'
  task :index do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:thinking_spinx_rails_env) do
          execute :rake, 'ts:index'
        end
      end
    end
  end

  desc 'Generate Sphinx indexes into the shared path.'
  task :generate do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:thinking_spinx_rails_env) do
          execute :rake, 'ts:generate'
        end
      end
    end
  end

  desc 'Restart the Sphinx search daemon.'
  task :restart do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:thinking_spinx_rails_env) do
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
        with rails_env: fetch(:thinking_spinx_rails_env) do
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
        with rails_env: fetch(:thinking_spinx_rails_env) do
          execute :rake, 'ts:configure'
        end
      end
    end
  end

  desc 'Stop the Sphinx search daemon.'
  task :stop do
    on roles fetch(:thinking_sphinx_roles) do
      within current_path do
        with rails_env: fetch(:thinking_spinx_rails_env) do
          execute :rake, 'ts:stop'
        end
      end
    end
  end
end
