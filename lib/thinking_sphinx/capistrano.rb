Capistrano::Configuration.instance(:must_exist).load do
  namespace :thinking_sphinx do
    desc 'Generate the Sphinx configuration file.'
    task :configure do
      rake 'ts:configure'
    end

    desc 'Build Sphinx indexes into the shared path and symlink them into your release.'
    task :index do
      rake 'ts:index'
    end
    after 'thinking_sphinx:index', 'thinking_sphinx:symlink_indexes'

    desc 'Start the Sphinx search daemon.'
    task :start do
      rake 'ts:start'
    end
    before 'thinking_sphinx:start', 'thinking_sphinx:configure'

    desc 'Stop the Sphinx search daemon.'
    task :stop do
      rake 'ts:stop'
    end

    desc 'Restart the Sphinx search daemon.'
    task :restart do
      rake 'ts:stop ts:configure ts:start'
    end

    desc <<-DESC
Stop, reindex, and then start the Sphinx search daemon. This task must be executed \
if you alter the structure of your indexes.
    DESC
    task :rebuild do
      rake 'ts:rebuild'
    end
    after 'thinking_sphinx:rebuild', 'thinking_sphinx:symlink_indexes'

    desc 'Create the shared folder for sphinx indexes.'
    task :shared_sphinx_folder do
      rails_env = fetch(:rails_env, 'production')
      run "mkdir -p #{shared_path}/db/sphinx/#{rails_env}"
    end

    desc 'Symlink Sphinx indexes from the shared folder to the latest release.'
    task :symlink_indexes do
      run "if [ -d #{release_path} ]; then ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx; else ln -nfs #{shared_path}/db/sphinx #{current_path}/db/sphinx; fi;"
    end

    # Logical flow for deploying an app
    after  'deploy:cold',            'thinking_sphinx:index'
    after  'deploy:cold',            'thinking_sphinx:start'
    after  'deploy:setup',           'thinking_sphinx:shared_sphinx_folder'
    after  'deploy:finalize_update', 'thinking_sphinx:symlink_indexes'

    def rake(tasks)
      rails_env = fetch(:rails_env, 'production')
      rake = fetch(:rake, 'rake')
      tasks += ' INDEX_ONLY=true' if ENV['INDEX_ONLY'] == 'true'

      run "if [ -d #{release_path} ]; then cd #{release_path}; else cd #{current_path}; fi; if [ -f Rakefile ]; then #{rake} RAILS_ENV=#{rails_env} #{tasks}; fi;"
    end
  end
end
