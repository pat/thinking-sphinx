Capistrano::Configuration.instance(:must_exist).load do
  _cset(:thinking_sphinx_roles)   { :db }
  _cset(:thinking_sphinx_options) { {:roles => fetch(:thinking_sphinx_roles)} }

  namespace :thinking_sphinx do
    desc 'Generate the Sphinx configuration file.'
    task :configure, fetch(:thinking_sphinx_options) do
      rake 'ts:configure'
    end

    desc 'Build Sphinx indexes into the shared path.'
    task :index, fetch(:thinking_sphinx_options) do
      rake 'ts:index'
    end

    desc 'Generate Sphinx indexes into the shared path.'
    task :generate, fetch(:thinking_sphinx_options) do
      rake 'ts:generate'
    end

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

    desc 'Stop Sphinx, clear Sphinx index files, generate configuration file, start Sphinx, repopulate all data.'
    task :regenerate, fetch(:thinking_sphinx_options) do
      rake 'ts:regenerate'
    end

    def rake(tasks)
      rails_env = fetch(:rails_env, 'production')
      rake = fetch(:rake, 'rake')
      tasks += ' INDEX_ONLY=true' if ENV['INDEX_ONLY'] == 'true'

      run "if [ -d #{release_path} ]; then cd #{release_path}; else cd #{current_path}; fi; if [ -f Rakefile ]; then #{rake} RAILS_ENV=#{rails_env} #{tasks}; fi;"
    end
  end
end
