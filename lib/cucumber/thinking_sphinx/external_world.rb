module Cucumber
  module ThinkingSphinx
    class ExternalWorld
      def initialize(suppress_delta_output = true)
        set_flags suppress_delta_output
        create_indexes_folder
        prepare_and_start_daemon
        configure_cleanup
      end
      
      private
      
      def config
        @config ||= ::ThinkingSphinx::Configuration.instance
      end
      
      def set_flags(suppress_delta_output)
        ::ThinkingSphinx.deltas_enabled        = true
        ::ThinkingSphinx.updates_enabled       = true
        ::ThinkingSphinx.suppress_delta_output = suppress_delta_output
      end
      
      def create_indexes_folder
        FileUtils.mkdir_p config.searchd_file_path
      end
      
      def prepare_and_start_daemon
        config.build
        config.controller.index
        config.controller.start
      end 
      
      def configure_cleanup
        Kernel.at_exit do
          config.controller.stop
          sleep(0.5) # Ensure Sphinx has shut down completely
        end
      end
    end
  end
end
