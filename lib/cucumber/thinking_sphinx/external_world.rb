require 'thinking_sphinx/test'

class Cucumber::ThinkingSphinx::ExternalWorld
  def initialize(suppress_delta_output = true)
    ::ThinkingSphinx::Test.init
    ::ThinkingSphinx::Test.start_with_autostop
  end
end
