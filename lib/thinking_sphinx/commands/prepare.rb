# frozen_string_literal: true

class ThinkingSphinx::Commands::Prepare < ThinkingSphinx::Commands::Base
  def call
    return if skip_directories?

    FileUtils.mkdir_p configuration.indices_location
  end

  private

  def type
    'prepare'
  end
end
