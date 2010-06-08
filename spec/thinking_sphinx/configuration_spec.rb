require 'spec/spec_helper'

describe ThinkingSphinx::Configuration do
  describe "environment class method" do
    before :each do
      Thread.current[:thinking_sphinx_environment] = nil
      
      ENV["RAILS_ENV"] = nil
    end

    it "should use the Merb environment value if set" do
      unless defined?(Merb)
        module ::Merb; end
      end

      ThinkingSphinx::Configuration.stub!(:defined? => true)
      Merb.stub!(:environment => "merb_production")
      ThinkingSphinx::Configuration.environment.should == "merb_production"

      Object.send :remove_const, :Merb
    end
    
    it "should use RAILS_ENV if set" do
      RAILS_ENV = 'global_rails'
      
      ThinkingSphinx::Configuration.environment.should == 'global_rails'
      
      Object.send :remove_const, :RAILS_ENV
    end

    it "should use the Rails environment value if set" do
      ENV["RAILS_ENV"] = "rails_production"
      ThinkingSphinx::Configuration.environment.should == "rails_production"
    end

    it "should default to development" do
      ThinkingSphinx::Configuration.environment.should == "development"
    end
  end
  
  describe '#version' do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
      @config.reset
    end
    
    it "should use the given version from sphinx.yml if there is one" do
      open("#{RAILS_ROOT}/config/sphinx.yml", "w") do |f|
        f.write  YAML.dump({'development' => {'version' => '0.9.7'}})
      end
      @config.reset
      
      @config.version.should == '0.9.7'
      
      FileUtils.rm "#{RAILS_ROOT}/config/sphinx.yml"
    end
    
    it "should detect the version from Riddle otherwise" do
      controller = @config.controller
      controller.stub!(:sphinx_version => '0.9.6')
      
      Riddle::Controller.stub!(:new => controller)
      @config.reset
      
      @config.version.should == '0.9.6'
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
          "ignore_chars"      => "e",
          "searchd_binary_name" => "sphinx-searchd",
          "indexer_binary_name" => "sphinx-indexer",
          "index_exact_words" => true,
          "indexed_models"    => ['Alpha', 'Beta']
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
        address port searchd_binary_name indexer_binary_name).each do |key|
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

      FileUtils.rm "#{RAILS_ROOT}/config/sphinx.yml"
    end
  end

  describe "index options" do
    before :each do
      @settings = {
        "development" => {"disable_range" => true}
      }

      open("#{RAILS_ROOT}/config/sphinx.yml", "w") do |f|
        f.write  YAML.dump(@settings)
      end

      @config = ThinkingSphinx::Configuration.instance
      @config.send(:parse_config)
    end

    it "should collect disable_range" do
      @config.index_options[:disable_range].should be_true
    end

    after :each do
      FileUtils.rm "#{RAILS_ROOT}/config/sphinx.yml"
    end
  end

  it "should insert set index options into the configuration file" do
    config = ThinkingSphinx::Configuration.instance
    
    ThinkingSphinx::Configuration::IndexOptions.each do |option|
      config.reset
      config.index_options[option.to_sym] = "something"
      config.build

      file = open(config.config_file) { |f| f.read }
      file.should match(/#{option}\s+= something/)

      config.index_options[option.to_sym] = nil
    end
  end

  it "should insert set source options into the configuration file" do
    config = ThinkingSphinx::Configuration.instance
    config.reset
    
    config.source_options[:sql_query_pre] = ["something"]
    ThinkingSphinx::Configuration::SourceOptions.each do |option|
      config.source_options[option.to_sym] ||= "something"
      config.build

      file = open(config.config_file) { |f| f.read }
      file.should match(/#{option}\s+= something/)

      config.source_options.delete option.to_sym
    end
    
    config.source_options[:sql_query_pre] = nil  
  end
  
  it "should not blow away delta or utf options if sql pre is specified in config" do
    config = ThinkingSphinx::Configuration.instance
    config.reset
    
    config.source_options[:sql_query_pre] = ["a pre query"]
    config.build
    file = open(config.config_file) { |f| f.read }
    
    file.should match(/sql_query_pre = a pre query\n\s*sql_query_pre = UPDATE `\w+` SET `delta` = 0 WHERE `delta` = 1/im)
    file.should match(/sql_query_pre = a pre query\n\s*sql_query_pre = \n/im)
    
    config.source_options[:sql_query_pre] = nil
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
  
  describe '#client' do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
      @config.address     = 'domain.url'
      @config.port        = 3333
      @config.configuration.searchd.max_matches = 100
    end
    
    it "should return an instance of Riddle::Client" do
      @config.client.should be_a(Riddle::Client)
    end
    
    it "should use the configuration address" do
      @config.client.server.should == 'domain.url'
    end
    
    it "should use the configuration port" do
      @config.client.port.should == 3333
    end
    
    it "should use the configuration max matches" do
      @config.client.max_matches.should == 100
    end
  end
  
  describe '#models_by_crc' do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
    end
    
    it "should return a hash" do
      @config.models_by_crc.should be_a(Hash)
    end
    
    it "should pair class names to their crc codes" do
      @config.models_by_crc[Person.to_crc32].should == 'Person'
      @config.models_by_crc[Alpha.to_crc32].should  == 'Alpha'
    end
  end
end
