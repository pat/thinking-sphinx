require 'spec/spec_helper'

describe ThinkingSphinx::Configuration do
  describe "environment class method" do
    before :each do
      ThinkingSphinx::Configuration.send(:class_variable_set, :@@environment, nil)
      
      ENV["RAILS_ENV"] = nil
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

  describe "block configuration" do
    it "should let the user set-up a custom app_root" do
      ThinkingSphinx::Configuration.configure do |config|
        config.app_root = "/here/somewhere"
      end
      ThinkingSphinx::Configuration.instance.app_root.should == "/here/somewhere"
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