require 'spec_helper'

describe ThinkingSphinx do
  describe '.context' do
    it "should return a Context instance" do
      ThinkingSphinx.context.should be_a(ThinkingSphinx::Context)
    end
    
    it "should remember changes to the Context instance" do
      models = ThinkingSphinx.context.indexed_models
      
      ThinkingSphinx.context.indexed_models.replace([:model])
      ThinkingSphinx.context.indexed_models.should == [:model]
      
      ThinkingSphinx.context.indexed_models.replace(models)
    end
  end
  
  describe '.reset_context!' do
    it "should remove the existing Context instance" do
      existing = ThinkingSphinx.context
      
      ThinkingSphinx.reset_context!
      ThinkingSphinx.context.should_not == existing
      
      ThinkingSphinx.reset_context! existing
    end
  end
    
  describe '.define_indexes?' do
    it "should define indexes by default" do
      ThinkingSphinx.define_indexes?.should be_true
    end
  end
  
  describe '.define_indexes=' do
    it "should disable index definition" do
      ThinkingSphinx.define_indexes = false
      ThinkingSphinx.define_indexes?.should be_false
    end
  
    it "should enable index definition" do
      ThinkingSphinx.define_indexes = false
      ThinkingSphinx.define_indexes?.should be_false
      ThinkingSphinx.define_indexes = true
      ThinkingSphinx.define_indexes?.should be_true
    end
  end
  
  describe '.deltas_enabled?' do
    it "should index deltas by default" do
      ThinkingSphinx.deltas_enabled?.should be_true
    end
  end
  
  describe '.deltas_enabled=' do
    it "should disable delta indexing" do
      ThinkingSphinx.deltas_enabled = false
      ThinkingSphinx.deltas_enabled?.should be_false
    end
  
    it "should enable delta indexing" do
      ThinkingSphinx.deltas_enabled = false
      ThinkingSphinx.deltas_enabled?.should be_false
      ThinkingSphinx.deltas_enabled = true
      ThinkingSphinx.deltas_enabled?.should be_true
    end
  end
  
  describe '.updates_enabled?' do
    it "should update indexes by default" do
      ThinkingSphinx.updates_enabled = nil
      ThinkingSphinx.updates_enabled?.should be_true
    end
  end
  
  describe '.updates_enabled=' do
    it "should disable index updating" do
      ThinkingSphinx.updates_enabled = false
      ThinkingSphinx.updates_enabled?.should be_false
    end
  
    it "should enable index updating" do
      ThinkingSphinx.updates_enabled = false
      ThinkingSphinx.updates_enabled?.should be_false
      ThinkingSphinx.updates_enabled = true
      ThinkingSphinx.updates_enabled?.should be_true
    end
  end
  
  describe '.sphinx_running?' do
    it "should always say Sphinx is running if flagged as being on a remote machine" do
      ThinkingSphinx.remote_sphinx = true
      ThinkingSphinx.stub!(:sphinx_running_by_pid? => false)
    
      ThinkingSphinx.sphinx_running?.should be_true
    end
  
    it "should actually pay attention to Sphinx if not on a remote machine" do
      ThinkingSphinx.remote_sphinx = false
      ThinkingSphinx.stub!(:sphinx_running_by_pid? => false)
      ThinkingSphinx.sphinx_running?.should be_false
    
      ThinkingSphinx.stub!(:sphinx_running_by_pid? => true)
      ThinkingSphinx.sphinx_running?.should be_true
    end
  end
  
  describe '.version' do
    it "should return the version from the stored YAML file" do
      version = Jeweler::VersionHelper.new(
        File.join(File.dirname(__FILE__), '..')
      ).to_s
      
      ThinkingSphinx.version.should == version
    end
  end
  
  describe "use_group_by_shortcut? method" do
    before :each do
      adapter = defined?(JRUBY_VERSION) ? :JdbcAdapter : :MysqlAdapter
      unless ::ActiveRecord::ConnectionAdapters.const_defined?(adapter)
        pending "No MySQL"
        return
      end
      
      @connection = stub('adapter',
        :select_all => true,
        :class      => ActiveRecord::ConnectionAdapters::MysqlAdapter,
        :config => {:adapter => defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql'}
      )
      ::ActiveRecord::Base.stub!(
        :connection => @connection
      )
      
      ThinkingSphinx.reset_use_group_by_shortcut
    end
    
    it "should return true if no ONLY_FULL_GROUP_BY" do
      @connection.stub!(
        :select_all => {:a => "OTHER SETTINGS"}
      )
      
      ThinkingSphinx.use_group_by_shortcut?.should be_true
    end
  
    it "should return true if NULL value" do
      @connection.stub!(
        :select_all => {:a => nil}
      )
      
      ThinkingSphinx.use_group_by_shortcut?.should be_true
    end

    it "should return true if using mysql2 gem" do
      @connection.stub!(
        :class => ActiveRecord::ConnectionAdapters::Mysql2Adapter,
        :select_all => {:a => ""}
      )

      ThinkingSphinx.use_group_by_shortcut?.should be_true
    end
  
    it "should return false if ONLY_FULL_GROUP_BY is set" do
      @connection.stub!(
        :select_all => {:a => "OTHER SETTINGS,ONLY_FULL_GROUP_BY,blah"}
      )
      
      ThinkingSphinx.use_group_by_shortcut?.should be_false
    end
    
    it "should return false if ONLY_FULL_GROUP_BY is set in any of the values" do
      @connection.stub!(
        :select_all => {
          :a => "OTHER SETTINGS",
          :b => "ONLY_FULL_GROUP_BY"
        }
      )
      
      ThinkingSphinx.use_group_by_shortcut?.should be_false
    end
    
    describe "if not using MySQL" do
      before :each do
        adapter = defined?(JRUBY_VERSION) ? 'JdbcAdapter' : 'PostgreSQLAdapter'
        unless ::ActiveRecord::ConnectionAdapters.const_defined?(adapter)
          pending "No PostgreSQL"
          return
        end
        
        @connection = stub(adapter).as_null_object
        @connection.stub!(
          :select_all => true,
          :config => {:adapter => defined?(JRUBY_VERSION) ? 'jdbcpostgresql' : 'postgresql'}
        )
        ::ActiveRecord::Base.stub!(
          :connection => @connection
        )
      end
    
      it "should return false" do
        ThinkingSphinx.use_group_by_shortcut?.should be_false
      end
    
      it "should not call select_all" do
        @connection.should_not_receive(:select_all)
        
        ThinkingSphinx.use_group_by_shortcut?
      end
    end
  end
end
