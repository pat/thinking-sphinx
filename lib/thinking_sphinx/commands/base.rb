# frozen_string_literal: true

class ThinkingSphinx::Commands::Base
  include ThinkingSphinx::WithOutput

  def self.call(configuration, options, stream = STDOUT)
    new(configuration, options, stream).call_with_handling
  end

  def call_with_handling
    call
  rescue Riddle::CommandFailedError => error
    handle_failure error.command_result
  end

  private

  delegate :controller, :to => :configuration

  def command(command, extra_options = {})
    ThinkingSphinx::Commander.call(
      command, configuration, options.merge(extra_options), stream
    )
  end

  def command_output(output)
    return "See above\n" if output.nil?

    "\n\t" + output.gsub("\n", "\n\t")
  end

  def handle_failure(result)
    stream.puts <<-TXT

The Sphinx #{type} command failed:
  Command: #{result.command}
  Status:  #{result.status}
  Output:  #{command_output result.output}
There may be more information about the failure in #{configuration.searchd.log}.
    TXT
    exit(result.status || 1)
  end

  def log(message)
    return if options[:silent]

    stream.puts message
  end

  def skip_directories?
    configuration.settings['skip_directory_creation']
  end
end
