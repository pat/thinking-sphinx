# frozen_string_literal: true

class ThinkingSphinx::Interfaces::Base
  include ThinkingSphinx::WithOutput

  private

  def command(command, extra_options = {})
    ThinkingSphinx::Commander.call(
      command, configuration, options.merge(extra_options), stream
    )
  end
end
