class ThinkingSphinx::Commands::StartAttached < ThinkingSphinx::Commands::Base
  def call
    FileUtils.mkdir_p configuration.indices_location

    unless pid = fork
      controller.start :verbose => options[:verbose], :nodetach => true
    end

    Signal.trap('TERM') { Process.kill(:TERM, pid) }
    Signal.trap('INT')  { Process.kill(:TERM, pid) }

    Process.wait(pid)
  end

  private

  def type
    'start'
  end
end
