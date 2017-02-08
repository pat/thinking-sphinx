namespace :load do
  task :defaults do
    set :thinking_sphinx_role, :app
  end
end

namespace :thinking_sphinx do
  desc 'Generate the Sphinx configuration file.'
  task :configure do
    on roles(fetch(:thinking_sphinx_role)) do
      within current_path do
        execute :bundle, 'exec', :rake, 'ts:configure'
      end
    end
  end

  desc 'Build Sphinx indexes into the shared path and symlink them into your release.'
  task :index do
    on roles(fetch(:thinking_sphinx_role)) do
      within current_path do
        execute :bundle, 'exec', :rake, 'ts:index'
      end
      # rake 'ts:index'
    end
  end

  desc 'Start the Sphinx search daemon.'
  task :start do
    on roles(fetch(:thinking_sphinx_role)) do
      within current_path do
        execute :bundle, 'exec', :rake, 'ts:start'
      end
    end
  end
  before 'thinking_sphinx:start', 'thinking_sphinx:configure'

  desc 'Stop the Sphinx search daemon.'
  task :stop do
    on roles(fetch(:thinking_sphinx_role)) do
      within current_path do
        execute :bundle, 'exec', :rake, 'ts:stop'
      end
    end
  end

  desc 'Restart the Sphinx search daemon.'
  task :restart do
    on roles(fetch(:thinking_sphinx_role)) do
      within current_path do
        execute :bundle, 'exec', :rake, 'ts:start'
      end
    end
  end

  desc <<-DESC
Stop, reindex, and then start the Sphinx search daemon. This task must be executed \
if you alter the structure of your indexes.
  DESC
  task :rebuild do
    on roles(fetch(:thinking_sphinx_role)) do
      within current_path do
        execute :bundle, 'exec', :rake, 'ts:rebuild'
      end
    end
  end

  after 'deploy:finished', 'thinking_sphinx:index'
  after 'deploy:finished', 'thinking_sphinx:start'
  set :linked_dirs, %w{ db/sphinx }

end
