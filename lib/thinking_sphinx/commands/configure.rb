# frozen_string_literal: true

class ThinkingSphinx::Commands::Configure < ThinkingSphinx::Commands::Base
  def call
    log "Generating configuration to #{configuration.configuration_file}"

    configuration.render_to_file
  end

  private

  def type
    'configure'
  end
end
