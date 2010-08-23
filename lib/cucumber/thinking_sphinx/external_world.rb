require 'thinking_sphinx/test'

module Cucumber
  module ThinkingSphinx
    class ExternalWorld
      def initialize(suppress_delta_output = true)
        ::ThinkingSphinx::Test.init
        ::ThinkingSphinx::Test.start_with_autostop
      end
    end
  end
end
