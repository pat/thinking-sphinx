# frozen_string_literal: true

class ThinkingSphinx::Commands::Running < ThinkingSphinx::Commands::Base
  def call
    return true if configuration.settings['skip_running_check']

    controller.running?
  end

  private

  def type
    'running'
  end
end
