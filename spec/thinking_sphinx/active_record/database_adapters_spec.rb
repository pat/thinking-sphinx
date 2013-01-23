require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters do
  let(:model) { double('model') }

  describe '.adapter_for' do
    it "returns a MysqlAdapter object for :mysql" do
      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        stub(:adapter_type_for => :mysql)

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.adapter_for(model).
        should be_a(
          ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter
        )
    end

    it "returns a PostgreSQLAdapter object for :postgresql" do
      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        stub(:adapter_type_for => :postgresql)

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.adapter_for(model).
        should be_a(
          ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter
        )
    end

    it "instantiates using the default adapter if one is provided" do
      adapter_class    = double('adapter class')
      adapter_instance = double('adapter instance')

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.default = adapter_class
      adapter_class.stub!(:new => adapter_instance)

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.adapter_for(model).
        should == adapter_instance

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.default = nil
    end

    it "raises an exception for other responses" do
      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        stub(:adapter_type_for => :sqlite)

      lambda {
        ThinkingSphinx::ActiveRecord::DatabaseAdapters.adapter_for(model)
      }.should raise_error
    end
  end

  describe '.adapter_type_for' do
    let(:klass)      { double('connection class') }
    let(:connection) { double('connection', :class => klass) }
    let(:model)      { double('model', :connection => connection) }

    it "translates a normal MySQL adapter" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::MysqlAdapter')

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model).should == :mysql
    end

    it "translates a MySQL2 adapter" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::Mysql2Adapter')

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model).should == :mysql
    end

    it "translates a normal PostgreSQL adapter" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter')

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model).should == :postgresql
    end

    it "translates a JDBC MySQL adapter to MySQL" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      connection.stub(:config => {:adapter => 'jdbcmysql'})

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model).should == :mysql
    end

    it "translates a JDBC PostgreSQL adapter to PostgreSQL" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      connection.stub(:config => {:adapter => 'jdbcpostgresql'})

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model).should == :postgresql
    end

    it "translates a JDBC adapter with MySQL connection string to MySQL" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      connection.stub(:config => {:adapter => 'jdbc',
                                  :url => 'jdbc:mysql://127.0.0.1:3306/sphinx'})

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model).should == :mysql
    end

    it "translates a JDBC adapter with PostgresSQL connection string to PostgresSQL" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      connection.stub(:config => {:adapter => 'jdbc',
                                  :url => 'jdbc:postgresql://127.0.0.1:3306/sphinx'})

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model).should == :postgresql
    end

    it "returns other JDBC adapters without translation" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      connection.stub(:config => {:adapter => 'jdbcmssql'})

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model).should == 'jdbcmssql'
    end

    it "returns other unknown adapters without translation" do
      klass.stub(:name => 'ActiveRecord::ConnectionAdapters::FooAdapter')

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model).
        should == 'ActiveRecord::ConnectionAdapters::FooAdapter'
    end
  end
end
