# frozen_string_literal: true

class ThinkingSphinx::Railtie < Rails::Railtie
  config.to_prepare do
    ThinkingSphinx::Configuration.reset
  end

  config.after_initialize do
    require 'thinking_sphinx/active_record'
  end

  initializer 'thinking_sphinx.initialisation' do
    ActiveSupport.on_load(:active_record) do
      require 'thinking_sphinx/active_record'
    end

    if zeitwerk?
      ActiveSupport::Dependencies.autoload_paths.delete(
        Rails.root.join("app", "indices").to_s
      )
    end

    Rails.application.config.eager_load_paths -=
      ThinkingSphinx::Configuration.instance.index_paths
    Rails.application.config.eager_load_paths.freeze
  end

  rake_tasks do
    load File.expand_path('../tasks.rb', __FILE__)
  end

  def zeitwerk?
    return true if ActiveSupport::VERSION::MAJOR >= 7
    return false if ActiveSupport::VERSION::MAJOR <= 5

    Rails.application.config.autoloader == :zeitwerk
  end
end
