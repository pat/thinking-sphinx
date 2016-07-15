require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::DatabaseAdapters do
  let(:model) { double('model') }

  describe '.adapter_for' do
    it "returns a MysqlAdapter object for :mysql" do
      allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters).
        to receive_messages(:adapter_type_for => :mysql)

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.adapter_for(model)).
        to be_a(
          ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter
        )
    end

    it "returns a PostgreSQLAdapter object for :postgresql" do
      allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters).
        to receive_messages(:adapter_type_for => :postgresql)

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.adapter_for(model)).
        to be_a(
          ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter
        )
    end

    it "instantiates using the default adapter if one is provided" do
      adapter_class    = double('adapter class')
      adapter_instance = double('adapter instance')

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.default = adapter_class
      allow(adapter_class).to receive_messages(:new => adapter_instance)

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.adapter_for(model)).
        to eq(adapter_instance)

      ThinkingSphinx::ActiveRecord::DatabaseAdapters.default = nil
    end

    it "raises an exception for other responses" do
      allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters).
        to receive_messages(:adapter_type_for => :sqlite)

      expect {
        ThinkingSphinx::ActiveRecord::DatabaseAdapters.adapter_for(model)
      }.to raise_error
    end
  end

  describe '.adapter_type_for' do
    let(:klass)      { double('connection class') }
    let(:connection) { double('connection', :class => klass) }
    let(:model)      { double('model', :connection => connection) }

    it "translates a normal MySQL adapter" do
      allow(klass).to receive_messages(:name => 'ActiveRecord::ConnectionAdapters::MysqlAdapter')

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model)).to eq(:mysql)
    end

    it "translates a MySQL2 adapter" do
      allow(klass).to receive_messages(:name => 'ActiveRecord::ConnectionAdapters::Mysql2Adapter')

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model)).to eq(:mysql)
    end

    it "translates a normal PostgreSQL adapter" do
      allow(klass).to receive_messages(:name => 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter')

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model)).to eq(:postgresql)
    end

    it "translates a JDBC MySQL adapter to MySQL" do
      allow(klass).to receive_messages(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      allow(connection).to receive_messages(:config => {:adapter => 'jdbcmysql'})

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model)).to eq(:mysql)
    end

    it "translates a JDBC PostgreSQL adapter to PostgreSQL" do
      allow(klass).to receive_messages(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      allow(connection).to receive_messages(:config => {:adapter => 'jdbcpostgresql'})

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model)).to eq(:postgresql)
    end

    it "translates a JDBC adapter with MySQL connection string to MySQL" do
      allow(klass).to receive_messages(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      allow(connection).to receive_messages(:config => {:adapter => 'jdbc',
                                  :url => 'jdbc:mysql://127.0.0.1:3306/sphinx'})

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model)).to eq(:mysql)
    end

    it "translates a JDBC adapter with PostgresSQL connection string to PostgresSQL" do
      allow(klass).to receive_messages(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      allow(connection).to receive_messages(:config => {:adapter => 'jdbc',
                                  :url => 'jdbc:postgresql://127.0.0.1:3306/sphinx'})

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model)).to eq(:postgresql)
    end

    it "returns other JDBC adapters without translation" do
      allow(klass).to receive_messages(:name => 'ActiveRecord::ConnectionAdapters::JdbcAdapter')
      allow(connection).to receive_messages(:config => {:adapter => 'jdbcmssql'})

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model)).to eq('jdbcmssql')
    end

    it "returns other unknown adapters without translation" do
      allow(klass).to receive_messages(:name => 'ActiveRecord::ConnectionAdapters::FooAdapter')

      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        adapter_type_for(model)).
        to eq('ActiveRecord::ConnectionAdapters::FooAdapter')
    end
  end
end
