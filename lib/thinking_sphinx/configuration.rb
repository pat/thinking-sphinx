require 'erb'
require 'singleton'

module ThinkingSphinx
  # This class both keeps track of the configuration settings for Sphinx and
  # also generates the resulting file for Sphinx to use.
  # 
  # Here are the default settings, relative to RAILS_ROOT where relevant:
  #
  # config file::           config/#{environment}.sphinx.conf
  # searchd log file::      log/searchd.log
  # query log file::        log/searchd.query.log
  # pid file::              log/searchd.#{environment}.pid
  # searchd files::         db/sphinx/#{environment}/
  # address::               127.0.0.1
  # port::                  3312
  # allow star::            false
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
    
    SourceOptions = %w( mysql_connect_flags mysql_ssl_cert mysql_ssl_key
      mysql_ssl_ca sql_range_step sql_query_pre sql_query_post 
      sql_query_killlist sql_ranged_throttle sql_query_post_index unpack_zlib
      unpack_mysqlcompress unpack_mysqlcompress_maxsize )
    
    IndexOptions  = %w( charset_table charset_type charset_dictpath docinfo
      enable_star exceptions html_index_attrs html_remove_elements html_strip
      index_exact_words ignore_chars inplace_docinfo_gap inplace_enable
      inplace_hit_gap inplace_reloc_factor inplace_write_factor min_infix_len
      min_prefix_len min_stemming_len min_word_len mlock morphology ngram_chars
      ngram_len ondisk_dict overshort_step phrase_boundary phrase_boundary_step
      preopen stopwords stopwords_step wordforms )
    
    CustomOptions = %w( disable_range )
        
    attr_accessor :config_file, :searchd_log_file, :query_log_file,
      :pid_file, :searchd_file_path, :address, :port, :allow_star,
      :database_yml_file, :app_root, :bin_path, :model_directories,
      :delayed_job_priority, :searchd_binary_name, :indexer_binary_name
    
    attr_accessor :source_options, :index_options
    
    attr_reader :environment, :configuration
    
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
        self.app_root          = RAILS_ROOT if defined?(RAILS_ROOT)
        self.app_root          = Merb.root  if defined?(Merb)
        self.app_root        ||= app_root
      end
      
      @configuration = Riddle::Configuration.new
      @configuration.searchd.address    = "127.0.0.1"
      @configuration.searchd.port       = 3312
      @configuration.searchd.pid_file   = "#{self.app_root}/log/searchd.#{environment}.pid"
      @configuration.searchd.log        = "#{self.app_root}/log/searchd.log"
      @configuration.searchd.query_log  = "#{self.app_root}/log/searchd.query.log"
      
      self.database_yml_file    = "#{self.app_root}/config/database.yml"
      self.config_file          = "#{self.app_root}/config/#{environment}.sphinx.conf"
      self.searchd_file_path    = "#{self.app_root}/db/sphinx/#{environment}"
      self.allow_star           = false
      self.bin_path             = ""
      self.model_directories    = ["#{app_root}/app/models/"] +
        Dir.glob("#{app_root}/vendor/plugins/*/app/models/")
      self.delayed_job_priority = 0
      
      self.source_options  = {}
      self.index_options   = {
        :charset_type => "utf-8"
      }
      
      self.searchd_binary_name = "searchd"
      self.indexer_binary_name = "indexer"
            
      parse_config
      
      self
    end
    
    def self.environment
      Thread.current[:thinking_sphinx_environment] ||= (
        defined?(Merb) ? Merb.environment : ENV['RAILS_ENV']
      ) || "development"
    end
    
    def environment
      self.class.environment
    end
    
    def controller
      @controller ||= Riddle::Controller.new(@configuration, self.config_file)
    end
    
    # Generate the config file for Sphinx by using all the settings defined and
    # looping through all the models with indexes to build the relevant
    # indexer and searchd configuration, and sources and indexes details.
    #
    def build(file_path=nil)
      file_path ||= "#{self.config_file}"
      
      @configuration.indexes.clear
      
      ThinkingSphinx.context.indexed_models.each do |model|
        @configuration.indexes.concat model.constantize.to_riddle
      end
      
      open(file_path, "w") do |file|
        file.write @configuration.render
      end
    end
    
    def address
      @configuration.searchd.address
    end
    
    def address=(address)
      @configuration.searchd.address = address
    end
    
    def port
      @configuration.searchd.port
    end
    
    def port=(port)
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
    
    def client
      client = Riddle::Client.new address, port
      client.max_matches = configuration.searchd.max_matches || 1000
      client
    end
    
    def models_by_crc
      @models_by_crc ||= begin
        ThinkingSphinx.context.indexed_models.inject({}) do |hash, model|
          hash[model.constantize.to_crc32] = model
          Object.subclasses_of(model.constantize).each { |subclass|
            hash[subclass.to_crc32] = subclass.name
          }
          hash
        end
      end
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
    end
    
    def set_sphinx_setting(object, key, value, allowed = {})
      if object.is_a?(Hash)
        object[key.to_sym] = value if allowed.include?(key.to_s)
      else
        object.send("#{key}=", value) if object.respond_to?("#{key}")
        send("#{key}=", value) if self.respond_to?("#{key}")
      end
    end
  end
end
