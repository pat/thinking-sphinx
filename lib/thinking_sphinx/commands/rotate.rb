# frozen_string_literal: true

class ThinkingSphinx::Commands::Rotate < ThinkingSphinx::Commands::Base
  def call
    controller.rotate
  end

  private

  def type
    'rotate'
  end
end
