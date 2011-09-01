require 'erb'
require 'singleton'

module ThinkingSphinx
  # This class both keeps track of the configuration settings for Sphinx and
  # also generates the resulting file for Sphinx to use.
  #
  # Here are the default settings, relative to Rails.root where relevant:
  #
  # config file::           config/#{environment}.sphinx.conf
  # searchd log file::      log/searchd.log
  # query log file::        log/searchd.query.log
  # pid file::              log/searchd.#{environment}.pid
  # searchd files::         db/sphinx/#{environment}/
  # address::               127.0.0.1
  # port::                  9312
  # allow star::            false
  # stop timeout::          5
  # min prefix length::     1
  # min infix length::      1
  # mem limit::             64M
  # max matches::           1000
  # morphology::            nil
  # charset type::          utf-8
  # charset table::         nil
  # ignore chars::          nil
  # html strip::            false
  # html remove elements::  ''
  # searchd_binary_name::   searchd
  # indexer_binary_name::   indexer
  #
  # If you want to change these settings, create a YAML file at
  # config/sphinx.yml with settings for each environment, in a similar
  # fashion to database.yml - using the following keys: config_file,
  # searchd_log_file, query_log_file, pid_file, searchd_file_path, port,
  # allow_star, enable_star, min_prefix_len, min_infix_len, mem_limit,
  # max_matches, morphology, charset_type, charset_table, ignore_chars,
  # html_strip, html_remove_elements, delayed_job_priority,
  # searchd_binary_name, indexer_binary_name.
  #
  # I think you've got the idea.
  #
  # Each setting in the YAML file is optional - so only put in the ones you
  # want to change.
  #
  # Keep in mind, if for some particular reason you're using a version of
  # Sphinx older than 0.9.8 r871 (that's prior to the proper 0.9.8 release),
  # don't set allow_star to true.
  #
  class Configuration
    include Singleton

    SourceOptions = Riddle::Configuration::SQLSource.settings.map { |setting|
      setting.to_s
    } - %w( type sql_query_pre sql_query sql_joined_field sql_file_field
      sql_query_range sql_attr_uint sql_attr_bool sql_attr_bigint sql_query_info
      sql_attr_timestamp sql_attr_str2ordinal sql_attr_float sql_attr_multi
      sql_attr_string sql_attr_str2wordcount sql_column_buffers sql_field_string
      sql_field_str2wordcount )
    IndexOptions  = Riddle::Configuration::Index.settings.map     { |setting|
      setting.to_s
    } - %w( source prefix_fields infix_fields )
    CustomOptions = %w( disable_range use_64_bit )

    attr_accessor :searchd_file_path, :allow_star, :app_root,
      :model_directories, :delayed_job_priority, :indexed_models, :use_64_bit,
      :touched_reindex_file, :stop_timeout, :version

    attr_accessor :source_options, :index_options

    attr_reader :configuration, :controller

    @@environment = nil

    # Load in the configuration settings - this will look for config/sphinx.yml
    # and parse it according to the current environment.
    #
    def initialize(app_root = Dir.pwd)
      self.reset
    end

    def self.configure(&block)
      yield instance
      instance.reset(instance.app_root)
    end

    def reset(custom_app_root=nil)
      if custom_app_root
        self.app_root = custom_app_root
      else
        self.app_root   = Merb.root                  if defined?(Merb)
        self.app_root   = Sinatra::Application.root  if defined?(Sinatra)
        self.app_root   = Rails.root                 if defined?(Rails)
        self.app_root ||= app_root
      end

      @configuration = Riddle::Configuration.new
      @configuration.searchd.pid_file   = "#{self.app_root}/log/searchd.#{environment}.pid"
      @configuration.searchd.log        = "#{self.app_root}/log/searchd.log"
      @configuration.searchd.query_log  = "#{self.app_root}/log/searchd.query.log"

      @controller = Riddle::Controller.new @configuration,
        "#{self.app_root}/config/#{environment}.sphinx.conf"

      self.address              = "127.0.0.1"
      self.port                 = 9312
      self.searchd_file_path    = "#{self.app_root}/db/sphinx/#{environment}"
      self.allow_star           = false
      self.stop_timeout         = 5
      self.model_directories    = ["#{app_root}/app/models/"] +
        Dir.glob("#{app_root}/vendor/plugins/*/app/models/")
      self.delayed_job_priority = 0
      self.indexed_models       = []

      self.source_options  = {}
      self.index_options   = {
        :charset_type => "utf-8"
      }

      self.version = nil
      parse_config
      self.version ||= @controller.sphinx_version

      self
    end

    def self.environment
      @@environment ||= if defined?(Merb)
        Merb.environment
      elsif defined?(Rails)
        Rails.env
      elsif defined?(Sinatra)
        Sinatra::Application.environment.to_s
      else
        ENV['RAILS_ENV'] || 'development'
      end
    end

    def self.reset_environment
      ThinkingSphinx.mutex.synchronize do
        @@environment = nil
      end
    end

    def environment
      self.class.environment
    end

    def generate
      @configuration.indexes.clear

      ThinkingSphinx.context.indexed_models.each do |model|
        model = model.constantize
        model.define_indexes
        @configuration.indexes.concat model.to_riddle

        enforce_common_attribute_types
      end
    end

    # Generate the config file for Sphinx by using all the settings defined and
    # looping through all the models with indexes to build the relevant
    # indexer and searchd configuration, and sources and indexes details.
    #
    def build(file_path=nil)
      file_path ||= "#{self.config_file}"

      generate

      open(file_path, "w") do |file|
        file.write @configuration.render
      end
    end

    def address
      @address
    end

    def address=(address)
      @address = address
      @configuration.searchd.address = address
    end

    def port
      @port
    end

    def port=(port)
      @port = port
      @configuration.searchd.port = port
    end

    def pid_file
      @configuration.searchd.pid_file
    end

    def pid_file=(pid_file)
      @configuration.searchd.pid_file = pid_file
    end

    def searchd_log_file
      @configuration.searchd.log
    end

    def searchd_log_file=(file)
      @configuration.searchd.log = file
    end

    def query_log_file
      @configuration.searchd.query_log
    end

    def query_log_file=(file)
      @configuration.searchd.query_log = file
    end

    def config_file
      @controller.path
    end

    def config_file=(file)
      @controller.path = file
    end

    def bin_path
      @controller.bin_path
    end

    def bin_path=(path)
      @controller.bin_path = path
    end

    def searchd_binary_name
      @controller.searchd_binary_name
    end

    def searchd_binary_name=(name)
      @controller.searchd_binary_name = name
    end

    def indexer_binary_name
      @controller.indexer_binary_name
    end

    def indexer_binary_name=(name)
      @controller.indexer_binary_name = name
    end

    attr_accessor :timeout

    def client
      client = Riddle::Client.new address, port,
        configuration.searchd.client_key
      client.max_matches = configuration.searchd.max_matches || 1000
      client.timeout = timeout || 0
      client
    end

    def models_by_crc
      @models_by_crc ||= begin
        ThinkingSphinx.context.indexed_models.inject({}) do |hash, model|
          hash[model.constantize.to_crc32] = model
          model.constantize.descendants.each { |subclass|
            hash[subclass.to_crc32] = subclass.name
          }
          hash
        end
      end
    end

    def touch_reindex_file(output)
      return FileUtils.touch(@touched_reindex_file) if @touched_reindex_file and output =~ /succesfully sent SIGHUP to searchd/
      false
    end

    private

    # Parse the config/sphinx.yml file - if it exists - then use the attribute
    # accessors to set the appropriate values. Nothing too clever.
    #
    def parse_config
      path = "#{app_root}/config/sphinx.yml"
      return unless File.exists?(path)

      conf = YAML::load(ERB.new(IO.read(path)).result)[environment]

      conf.each do |key,value|
        self.send("#{key}=", value) if self.respond_to?("#{key}=")

        set_sphinx_setting self.source_options, key, value, SourceOptions
        set_sphinx_setting self.index_options,  key, value, IndexOptions
        set_sphinx_setting self.index_options,  key, value, CustomOptions
        set_sphinx_setting @configuration.searchd, key, value
        set_sphinx_setting @configuration.indexer, key, value
      end unless conf.nil?

      self.bin_path += '/' unless self.bin_path.blank?

      if self.allow_star
        self.index_options[:enable_star]    = true
        self.index_options[:min_prefix_len] = 1
      end

      ThinkingSphinx::Attribute::SphinxTypeMappings.merge(
        :string => :sql_attr_string
      ) if Riddle.loaded_version.to_i > 1
    end

    def set_sphinx_setting(object, key, value, allowed = {})
      if object.is_a?(Hash)
        object[key.to_sym] = value if allowed.include?(key.to_s)
      else
        object.send("#{key}=", value) if object.respond_to?("#{key}")
        send("#{key}=", value) if self.respond_to?("#{key}")
      end
    end

    def enforce_common_attribute_types
      sql_indexes = configuration.indexes.reject { |index|
        index.is_a? Riddle::Configuration::DistributedIndex
      }

      return unless sql_indexes.any? { |index|
        index.sources.any? { |source|
          source.sql_attr_bigint.include? :sphinx_internal_id
        }
      }

      sql_indexes.each { |index|
        index.sources.each { |source|
          next if source.sql_attr_bigint.include? :sphinx_internal_id

          source.sql_attr_bigint << :sphinx_internal_id
          source.sql_attr_uint.delete :sphinx_internal_id
        }
      }
    end
  end
end
