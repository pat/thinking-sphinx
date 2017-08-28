class ThinkingSphinx::Commands::Stop < ThinkingSphinx::Commands::Base
  def call
    unless controller.running?
      log 'searchd is not currently running.'
      return
    end

    pid = controller.pid
    until !controller.running? do
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
