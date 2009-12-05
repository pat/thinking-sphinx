require 'spec/spec_helper'

describe ThinkingSphinx::ActiveRecord::Tailor do
  describe "use_group_by_shortcut? method" do
    before :each do
      @connection = stub('adapter', :select_all => true)
      Person.stub!(:connection => @connection)
      Person.sphinx_database_adapter.stub!(:sphinx_identifier => 'mysql')
      @tailor = ThinkingSphinx::ActiveRecord::Tailor.new(
        stub('source', :model => Person)
      )
    end
    
    it "should return true if no ONLY_FULL_GROUP_BY" do
      @connection.stub!(
        :select_all => {:a => "OTHER SETTINGS"}
      )
      
      @tailor.use_group_by_shortcut?.should be_true
    end
  
    it "should return true if NULL value" do
      @connection.stub!(
        :select_all => {:a => nil}
      )
      
      @tailor.use_group_by_shortcut?.should be_true
    end
  
    it "should return false if ONLY_FULL_GROUP_BY is set" do
      @connection.stub!(
        :select_all => {:a => "OTHER SETTINGS,ONLY_FULL_GROUP_BY,blah"}
      )
      
      @tailor.use_group_by_shortcut?.should be_false
    end
    
    it "should return false if ONLY_FULL_GROUP_BY is set in any of the values" do
      @connection.stub!(
        :select_all => {
          :a => "OTHER SETTINGS",
          :b => "ONLY_FULL_GROUP_BY"
        }
      )
      
      @tailor.use_group_by_shortcut?.should be_false
    end
    
    describe "if not using MySQL" do
      before :each do
        @connection = stub('adapter', :select_all => true)
        Person.stub!(:connection => @connection)
        Person.sphinx_database_adapter.stub!(:sphinx_identifier => 'pgsql')
        @tailor = ThinkingSphinx::ActiveRecord::Tailor.new(
          stub('source', :model => Person)
        )
      end
    
      it "should return false" do
        @tailor.use_group_by_shortcut?.should be_false
      end
    
      it "should not call select_all" do
        @connection.should_not_receive(:select_all)
        
        @tailor.use_group_by_shortcut?
      end
    end
  end
end
