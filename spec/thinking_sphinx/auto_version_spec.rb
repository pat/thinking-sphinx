require 'spec_helper'

describe ThinkingSphinx::AutoVersion do
  describe '.detect' do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
    end
    
    it "should require 0.9.8 if that is the detected version" do
      ThinkingSphinx::AutoVersion.should_receive(:require).
        with('riddle/0.9.8')
      
      @config.stub!(:version => '0.9.8')
      ThinkingSphinx::AutoVersion.detect
    end
    
    it "should require 0.9.9 if that is the detected version" do
      ThinkingSphinx::AutoVersion.should_receive(:require).
        with('riddle/0.9.9')
      
      @config.stub!(:version => '0.9.9')
      ThinkingSphinx::AutoVersion.detect
    end
    
    it "should require 1.10-beta if that is the detected version" do
      ThinkingSphinx::AutoVersion.should_receive(:require).
        with('riddle/1.10')
      
      @config.stub!(:version => '1.10-beta')
      ThinkingSphinx::AutoVersion.detect
    end
    
    it "should require 1.10-beta if that is the detected version" do
      ThinkingSphinx::AutoVersion.should_receive(:require).
        with('riddle/1.10')
      
      @config.stub!(:version => '1.10-id64-beta')
      ThinkingSphinx::AutoVersion.detect
    end
    
    it "should output a warning if the detected version is unsupported" do
      STDERR.should_receive(:puts).with(/unsupported/i)
      
      @config.stub!(:version => '0.9.7')
      ThinkingSphinx::AutoVersion.detect
    end
    
    it "should output a warning if the version cannot be determined" do
      STDERR.should_receive(:puts).at_least(:once)
      
      @config.stub!(:version => nil)
      ThinkingSphinx::AutoVersion.detect
    end
  end
end
