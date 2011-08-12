require 'cucumber/thinking_sphinx/sql_logger'

module Cucumber
  module ThinkingSphinx
    class InternalWorld
      attr_accessor :temporary_directory, :migrations_directory,
        :models_directory, :fixtures_directory, :database_file
      attr_accessor :adapter, :database, :username,
        :password, :host

      def initialize
        pwd = Dir.pwd
        @temporary_directory  = "#{pwd}/tmp"
        @migrations_directory = "#{pwd}/features/thinking_sphinx/db/migrations"
        @models_directory     = "#{pwd}/features/thinking_sphinx/models"
        @fixtures_directory   = "#{pwd}/features/thinking_sphinx/db/fixtures"
        @database_file        = "#{pwd}/features/thinking_sphinx/database.yml"

        @adapter  = (ENV['DATABASE'] || 'mysql').gsub /^mysql$/, 'mysql2'
        @database = 'thinking_sphinx'
        @username = 'thinking_sphinx'
        # @password = 'thinking_sphinx'
        @host     = 'localhost'
      end

      def setup
        make_temporary_directory

        configure_cleanup
        configure_thinking_sphinx
        configure_active_record

        prepare_data
        setup_sphinx

        self
      end

      def configure_database
        ActiveRecord::Base.establish_connection database_settings
        self
      end

      private

      def config
        @config ||= ::ThinkingSphinx::Configuration.instance
      end

      def make_temporary_directory
        FileUtils.mkdir_p temporary_directory
        Dir["#{temporary_directory}/*"].each do |file|
          FileUtils.rm_rf file
        end
      end

      def configure_thinking_sphinx
        config.config_file        = "#{temporary_directory}/sphinx.conf"
        config.searchd_log_file   = "#{temporary_directory}/searchd.log"
        config.query_log_file     = "#{temporary_directory}/searchd.query.log"
        config.pid_file           = "#{temporary_directory}/searchd.pid"
        config.searchd_file_path  = "#{temporary_directory}/indexes/"

        ::ThinkingSphinx.suppress_delta_output = true
      end

      def configure_cleanup
        Kernel.at_exit do
          ::ThinkingSphinx::Configuration.instance.controller.stop
          sleep(0.5) # Ensure Sphinx has shut down completely
          ::ThinkingSphinx::ActiveRecord::LogSubscriber.logger.close
        end
      end

      def yaml_database_settings
        return {} unless File.exist?(@database_file)

        YAML.load open(@database_file)
      end

      def database_settings
        {
          'adapter'  => @adapter,
          'database' => @database,
          'username' => @username,
          'password' => @password,
          'host'     => @host
        }.merge yaml_database_settings
      end

      def configure_active_record
        ::ThinkingSphinx::ActiveRecord::LogSubscriber.logger = Logger.new(
          open("#{temporary_directory}/active_record.log", "a")
        )

        ActiveRecord::Base.connection.class.send(
          :include, Cucumber::ThinkingSphinx::SqlLogger
        )
      end

      def prepare_data
        ::ThinkingSphinx.deltas_enabled = false

        load_files migrations_directory
        load_files models_directory
        load_files fixtures_directory

        ::ThinkingSphinx.deltas_enabled = true
      end

      def load_files(path)
        files = Dir["#{path}/*.rb"].sort!
        files.each do |file|
          require file.gsub(/\.rb$/, '')
        end
      end

      def setup_sphinx
        FileUtils.mkdir_p config.searchd_file_path

        config.build
        config.controller.index
        config.controller.start
      end
    end
  end
end
