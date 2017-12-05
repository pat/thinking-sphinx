# frozen_string_literal: true

class ThinkingSphinx::Interfaces::Daemon
  include ThinkingSphinx::WithOutput

  def start
    if running?
      raise ThinkingSphinx::SphinxAlreadyRunning, 'searchd is already running'
    end

    if options[:nodetach]
      ThinkingSphinx::Commands::StartAttached.call configuration, options
    else
      ThinkingSphinx::Commands::StartDetached.call configuration, options
    end
  end

  def status
    if running?
      stream.puts "The Sphinx daemon searchd is currently running."
    else
      stream.puts "The Sphinx daemon searchd is not currently running."
    end
  end

  def stop
    ThinkingSphinx::Commands::Stop.call configuration, options
  end

  private

  delegate :controller, :to => :configuration
  delegate :running?,   :to => :controller
end
