require 'spec/spec_helper'

describe ThinkingSphinx::Configuration do
  describe "environment class method" do
    before :each do
      ThinkingSphinx::Configuration.send(:class_variable_set, :@@environment, nil)
      
      ENV["RAILS_ENV"]  = nil
    end
    
    it "should use the Merb environment value if set" do
      unless defined?(Merb)
        module Merb; end
      end
            
      ThinkingSphinx::Configuration.stub_method(:defined? => true)
      Merb.stub_method(:environment => "merb_production")
      ThinkingSphinx::Configuration.environment.should == "merb_production"
      
      Object.send(:remove_const, :Merb)
    end
    
    it "should use the Rails environment value if set" do
      ENV["RAILS_ENV"] = "rails_production"
      ThinkingSphinx::Configuration.environment.should == "rails_production"
    end
    
    it "should default to development" do
      ThinkingSphinx::Configuration.environment.should == "development"
    end
  end
  
  describe "environment instance method" do
    it "should return the class method" do
      ThinkingSphinx::Configuration.stub_method(:environment => "spec")
      ThinkingSphinx::Configuration.instance.environment.should == "spec"
      ThinkingSphinx::Configuration.should have_received(:environment)
    end    
  end
  
  describe "build method" do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
      
      @config.stub_methods(:load_models => true)
      
      ThinkingSphinx.stub_method :indexed_models => ["Person", "Friendship"]
      
      @adapter = ThinkingSphinx::MysqlAdapter.stub_instance(
        :setup => true
      )
      source = Riddle::Configuration::Source.stub_instance(
        :render => "source random { }",
        :name   => "random"
      )
      
      index_options = {
        :to_config            => "",
        :adapter              => :mysql,
        :delta?               => false,
        :options              => {},
        :name                 => "person",
        :model                => Person,
        :adapter_object       => @adapter,
        :to_riddle_for_core   => source,
        :to_riddle_for_delta  => source,
        :prefix_fields        => [],
        :infix_fields         => []
      }
      
      @person_index_a = ThinkingSphinx::Index.stub_instance index_options
      @person_index_b = ThinkingSphinx::Index.stub_instance index_options
      @friendship_index_a = ThinkingSphinx::Index.stub_instance index_options.merge(
        :name => "friendship", :model => Friendship
      )
      
      Person.stub_method(:sphinx_indexes => [@person_index_a, @person_index_b])
      Friendship.stub_method(:sphinx_indexes => [@friendship_index_a])
    end
        
    it "should load the models" do
      @config.build
      
      @config.should have_received(:load_models)
    end
    
    it "should use the configuration port" do
      @config.build
      
      file = open(@config.config_file) { |f| f.read }
      file.should match(/port\s+= #{@config.port}/)
    end
    
    it "should use the configuration's log file locations" do
      @config.build
      
      file = open(@config.config_file) { |f| f.read }
      file.should match(/log\s+= #{@config.searchd_log_file}/)
      file.should match(/query_log\s+= #{@config.query_log_file}/)
    end
    
    it "should use the configuration's pid file location" do
      @config.build
      
      file = open(@config.config_file) { |f| f.read }
      file.should match(/pid_file\s+= #{@config.pid_file}/)
    end
  end
  
  describe "load_models method" do
    it "should have some specs"
  end
  
  describe "parse_config method" do
    before :each do
      @settings = {
        "development" => {
          "config_file"       => "tmp/config/development.sphinx.conf",
          "searchd_log_file"  => "searchd_log_file.log",
          "query_log_file"    => "query_log_file.log",
          "pid_file"          => "pid_file.pid",
          "searchd_file_path" => "searchd/file/path",
          "address"           => "127.0.0.1",
          "port"              => 3333,
          "min_prefix_len"    => 2,
          "min_infix_len"     => 3,
          "mem_limit"         => "128M",
          "max_matches"       => 1001,
          "morphology"        => "stem_ru",
          "charset_type"      => "latin1",
          "charset_table"     => "table",
          "ignore_chars"      => "e"
        }
      }
      
      open("#{RAILS_ROOT}/config/sphinx.yml", "w") do |f|
        f.write  YAML.dump(@settings)
      end
    end
    
    it "should use the accessors to set the configuration values" do
      config = ThinkingSphinx::Configuration.instance
      config.send(:parse_config)
      
      %w(config_file searchd_log_file query_log_file pid_file searchd_file_path
        address port).each do |key|
        config.send(key).should == @settings["development"][key]
      end
    end
    
    after :each do
      FileUtils.rm "#{RAILS_ROOT}/config/sphinx.yml"
    end
  end
    
  describe "initialisation" do
    it "should have a default bin_path of nothing" do
      ThinkingSphinx::Configuration.instance.bin_path.should == ""
    end
    
    it "should append a / to bin_path if one is supplied" do
      @settings = {
        "development" => {
          "bin_path" => "path/to/somewhere"
        }
      }
      
      open("#{RAILS_ROOT}/config/sphinx.yml", "w") do |f|
        f.write  YAML.dump(@settings)
      end
      
      ThinkingSphinx::Configuration.instance.send(:parse_config)
      ThinkingSphinx::Configuration.instance.bin_path.should match(/\/$/)
    end
  end
  
  it "should insert set index options into the configuration file" do
    config = ThinkingSphinx::Configuration.instance
    ThinkingSphinx::Configuration::IndexOptions.each do |option|
      config.index_options[option.to_sym] = "something"
      config.build
      
      file = open(config.config_file) { |f| f.read }
      file.should match(/#{option}\s+= something/)
      
      config.index_options[option.to_sym] = nil
    end
  end
  
  it "should insert set source options into the configuration file" do
    config = ThinkingSphinx::Configuration.instance
    ThinkingSphinx::Configuration::SourceOptions.each do |option|
      config.source_options[option.to_sym] = "something"
      config.build
      
      file = open(config.config_file) { |f| f.read }
      file.should match(/#{option}\s+= something/)
      
      config.source_options[option.to_sym] = nil
    end
  end
  
  it "should set any explicit prefixed or infixed fields" do
    file = open(ThinkingSphinx::Configuration.instance.config_file) { |f|
      f.read
    }
    file.should match(/prefix_fields\s+= city/)
    file.should match(/infix_fields\s+= state/)    
  end
  
  it "should not have prefix fields in indexes where nothing is set" do
    file = open(ThinkingSphinx::Configuration.instance.config_file) { |f|
      f.read
    }
    file.should_not match(/index alpha_core\s+\{\s+[^\}]*prefix_fields\s+=[^\}]*\}/m)
  end
end