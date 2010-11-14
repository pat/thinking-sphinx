require 'spec_helper'

describe ThinkingSphinx::AbstractAdapter do
  describe '.detect' do
    let(:model) { stub('model') }
    
    it "returns a MysqlAdapter object for :mysql" do
      ThinkingSphinx::AbstractAdapter.stub(:adapter_for_model => :mysql)
      
      adapter = ThinkingSphinx::AbstractAdapter.detect(model)
      adapter.should be_a(ThinkingSphinx::MysqlAdapter)
    end
    
    it "returns a PostgreSQLAdapter object for :postgresql" do
      ThinkingSphinx::AbstractAdapter.stub(:adapter_for_model => :postgresql)
      
      adapter = ThinkingSphinx::AbstractAdapter.detect(model)
      adapter.should be_a(ThinkingSphinx::PostgreSQLAdapter)
    end
    
    it "raises an exception for other responses" do
      ThinkingSphinx::AbstractAdapter.stub(:adapter_for_model => :sqlite)
      
      lambda {
        ThinkingSphinx::AbstractAdapter.detect(model)
      }.should raise_error
    end
  end
  
  describe '.adapter_for_model' do
    let(:model) { stub('model') }
    
    after :each do
      ThinkingSphinx.database_adapter = nil
    end
    
    it "translates strings to symbols" do
      ThinkingSphinx.database_adapter = 'foo'
      
      ThinkingSphinx::AbstractAdapter.adapter_for_model(model).should == :foo
    end
    
    it "passes through symbols unchanged" do
      ThinkingSphinx.database_adapter = :bar
      
      ThinkingSphinx::AbstractAdapter.adapter_for_model(model).should == :bar
    end
    
    it "returns standard_adapter_for_model if database_adapter is not set" do
      ThinkingSphinx.database_adapter = nil
      ThinkingSphinx::AbstractAdapter.stub!(:standard_adapter_for_model => :baz)
      
      ThinkingSphinx::AbstractAdapter.adapter_for_model(model).should == :baz
    end
    
    it "calls the lambda and returns it if one is provided" do
      ThinkingSphinx.database_adapter = lambda { |model| :foo }
      
      ThinkingSphinx::AbstractAdapter.adapter_for_model(model).should == :foo
    end
  end
  
  describe '.standard_adapter_for_model' do
    let(:klass)      { stub('connection class') }
    let(:connection) { stub('connection', :class => klass) }
    let(:model)      { stub('model', :connection => connection) }
    
    it "translates a normal MySQL adapter" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::MysqlAdapter')
      
      ThinkingSphinx::AbstractAdapter.standard_adapter_for_model(model).
        should == :mysql
    end
    
    it "translates a MySQL plus adapter" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::MysqlplusAdapter')
      
      ThinkingSphinx::AbstractAdapter.standard_adapter_for_model(model).
        should == :mysql
    end
    
    it "translates a MySQL2 adapter" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::Mysql2Adapter')
      
      ThinkingSphinx::AbstractAdapter.standard_adapter_for_model(model).
        should == :mysql
    end
    
    it "translates a NullDB adapter to MySQL" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::NullDBAdapter')
      
      ThinkingSphinx::AbstractAdapter.standard_adapter_for_model(model).
        should == :mysql
    end
    
    it "translates a normal PostgreSQL adapter" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter')
      
      ThinkingSphinx::AbstractAdapter.standard_adapter_for_model(model).
        should == :postgresql
    end
    
    it "translates a JDBC MySQL adapter to MySQL" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      connection.stub(:config => {:adapter => 'jdbcmysql'})
      
      ThinkingSphinx::AbstractAdapter.standard_adapter_for_model(model).
        should == :mysql
    end
    
    it "translates a JDBC PostgreSQL adapter to PostgreSQL" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      connection.stub(:config => {:adapter => 'jdbcpostgresql'})
      
      ThinkingSphinx::AbstractAdapter.standard_adapter_for_model(model).
        should == :postgresql
    end
    
    it "returns other JDBC adapters without translation" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      connection.stub(:config => {:adapter => 'jdbcmssql'})
      
      ThinkingSphinx::AbstractAdapter.standard_adapter_for_model(model).
        should == 'jdbcmssql'
    end
    
    it "returns other unknown adapters without translation" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::FooAdapter')
      
      ThinkingSphinx::AbstractAdapter.standard_adapter_for_model(model).
        should == 'ActiveRecord::ConnectionAdapters::FooAdapter'
    end
  end
end
