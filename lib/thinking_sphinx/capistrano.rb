Capistrano::Configuration.instance(:must_exist).load do
  _cset(:thinking_sphinx_roles)   { :db }
  _cset(:thinking_sphinx_options) { {:roles => fetch(:thinking_sphinx_roles)} }

  namespace :thinking_sphinx do
    desc 'Generate the Sphinx configuration file.'
    task :configure, fetch(:thinking_sphinx_options) do
      rake 'ts:configure'
    end

    desc 'Build Sphinx indexes into the shared path and symlink them into your release.'
    task :index, fetch(:thinking_sphinx_options) do
      rake 'ts:index'
    end
    after 'thinking_sphinx:index', 'thinking_sphinx:symlink_indexes'

    desc 'Generate Sphinx indexes into the shared path and symlink them into your release.'
    task :generate, fetch(:thinking_sphinx_options) do
      rake 'ts:generate'
    end
    after 'thinking_sphinx:generate', 'thinking_sphinx:symlink_indexes'

    desc 'Start the Sphinx search daemon.'
    task :start, fetch(:thinking_sphinx_options) do
      rake 'ts:start'
    end
    before 'thinking_sphinx:start', 'thinking_sphinx:configure'

    desc 'Stop the Sphinx search daemon.'
    task :stop, fetch(:thinking_sphinx_options) do
      rake 'ts:stop'
    end

    desc 'Restart the Sphinx search daemon.'
    task :restart, fetch(:thinking_sphinx_options) do
      rake 'ts:stop ts:configure ts:start'
    end

    desc <<-DESC
Stop, reindex, and then start the Sphinx search daemon. This task must be executed \
if you alter the structure of your indexes.
    DESC
    task :rebuild, fetch(:thinking_sphinx_options) do
      rake 'ts:rebuild'
    end
    after 'thinking_sphinx:rebuild', 'thinking_sphinx:symlink_indexes'

    desc 'Stop Sphinx, clear Sphinx index files, generate configuration file, start Sphinx, repopulate all data.'
    task :regenerate, fetch(:thinking_sphinx_options) do
      rake 'ts:regenerate'
    end
    after 'thinking_sphinx:regenerate', 'thinking_sphinx:symlink_indexes'

    desc 'Create the shared folder for sphinx indexes.'
    task :shared_sphinx_folder, fetch(:thinking_sphinx_options) do
      rails_env = fetch(:rails_env, 'production')
      run "mkdir -p #{shared_path}/db/sphinx/#{rails_env}"
    end

    desc 'Symlink Sphinx indexes from the shared folder to the latest release.'
    task :symlink_indexes, fetch(:thinking_sphinx_options) do
      run "if [ -d #{release_path} ]; then ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx; else ln -nfs #{shared_path}/db/sphinx #{current_path}/db/sphinx; fi;"
    end

    # Logical flow for deploying an app
    after 'deploy:setup',           'thinking_sphinx:shared_sphinx_folder'
    after 'deploy:finalize_update', 'thinking_sphinx:symlink_indexes'

    def rake(tasks)
      rails_env = fetch(:rails_env, 'production')
      rake = fetch(:rake, 'rake')
      tasks += ' INDEX_ONLY=true' if ENV['INDEX_ONLY'] == 'true'

      run "if [ -d #{release_path} ]; then cd #{release_path}; else cd #{current_path}; fi; if [ -f Rakefile ]; then #{rake} RAILS_ENV=#{rails_env} #{tasks}; fi;"
    end
  end
end
