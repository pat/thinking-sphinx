# frozen_string_literal: true

class ThinkingSphinx::Commands::Stop < ThinkingSphinx::Commands::Base
  def call
    unless command :running
      log 'searchd is not currently running.'
      return
    end

    pid = controller.pid
    until !command :running do
      controller.stop options
      sleep(0.5)
    end

    log "Stopped searchd daemon (pid: #{pid})."
  end

  private

  def type
    'stop'
  end
end
