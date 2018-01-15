# frozen_string_literal: true

class ThinkingSphinx::Commands::Running < ThinkingSphinx::Commands::Base
  def call
    controller.running?
  end

  private

  def type
    'running'
  end
end
