# frozen_string_literal: true

class ThinkingSphinx::Commands::StartDetached < ThinkingSphinx::Commands::Base
  def call
    FileUtils.mkdir_p configuration.indices_location unless skip_directories?

    result = controller.start :verbose => options[:verbose]

    if command :running
      log "Started searchd successfully (pid: #{controller.pid})."
    else
      handle_failure result
    end
  end

  private

  def type
    'start'
  end
end
