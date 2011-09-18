require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::SQLSource do
  let(:model)      {
    double('model', :connection => connection, :name => 'User')
  }
  let(:connection) { double('connection', :instance_variable_get => db_config) }
  let(:db_config)  {
    {:host => 'localhost', :user => 'root', :database => 'default'}
  }
  let(:source)     { ThinkingSphinx::ActiveRecord::SQLSource.new(model) }
  let(:adapter)    { double('adapter') }

  before :each do
    ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter.
      stub!(:=== => true)
    ThinkingSphinx::ActiveRecord::DatabaseAdapters.
      stub!(:adapter_for => adapter)
  end

  describe '#adapter' do
    it "returns a database adapter for the model" do
      ThinkingSphinx::ActiveRecord::DatabaseAdapters.
        should_receive(:adapter_for).with(model).and_return(adapter)

      source.adapter.should == adapter
    end
  end

  describe '#attributes' do
    it "has the internal id attribute by default" do
      source.attributes.collect(&:name).should include('sphinx_internal_id')
    end

    it "has the internal class attribute by default" do
      source.attributes.collect(&:name).should include('sphinx_internal_class')
    end
  end

  describe '#delta_processor' do
    let(:processor) { double('processor') }

    it "returns the given processor" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :delta_processor => processor

      source.delta_processor.should == processor
    end
  end

  describe '#delta?' do
    it "returns the given delta setting" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :delta? => true

      source.should be_a_delta
    end
  end

  describe '#disable_range?' do
    it "returns the given range setting" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :disable_range? => true

      source.disable_range?.should be_true
    end
  end

  describe '#name' do
    it "defaults to the model name downcased with the core suffix" do
      source.name.should == 'user_core'
    end

    it "changes the suffix to delta if set to true" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :delta? => true

      source.name.should == 'user_delta'
    end

    it "allows for custom names, but adds the core suffix" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :name => 'people'

      source.name.should == 'people_core'
    end

    it "allows for custom names and adds the delta suffix if a delta source" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :name => 'people', :delta? => true

      source.name.should == 'people_delta'
    end
  end

  describe '#offset' do
    it "returns the given offset" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model, :offset => 12

      source.offset.should == 12
    end
  end

  describe '#render' do
    let(:builder) { double('builder', :sql_query_pre => []).as_null_object }

    before :each do
      ThinkingSphinx::ActiveRecord::SQLBuilder.stub! :new => builder
    end

    it "sets the sql_host setting from the model's database settings" do
      db_config[:host] = '12.34.56.78'

      source.render

      source.sql_host.should == '12.34.56.78'
    end

    it "defaults sql_host to localhost if the model has no host" do
      db_config[:host] = nil

      source.render

      source.sql_host.should == 'localhost'
    end

    it "sets the sql_user setting from the model's database settings" do
      db_config[:username] = 'pat'

      source.render

      source.sql_user.should == 'pat'
    end

    it "uses the user setting if username is not set in the model" do
      db_config[:username] = nil
      db_config[:user]     = 'pat'

      source.render

      source.sql_user.should == 'pat'
    end

    it "sets the sql_pass setting from the model's database settings" do
      db_config[:password] = 'swordfish'

      source.render

      source.sql_pass.should == 'swordfish'
    end

    it "escapes hashes in the password for sql_pass" do
      db_config[:password] = 'sword#fish'

      source.render

      source.sql_pass.should == 'sword\#fish'
    end

    it "sets the sql_db setting from the model's database settings" do
      db_config[:database] = 'rails_app'

      source.render

      source.sql_db.should == 'rails_app'
    end

    it "sets the sql_port setting from the model's database settings" do
      db_config[:port] = 5432

      source.render

      source.sql_port.should == 5432
    end

    it "sets the sql_sock setting from the model's database settings" do
      db_config[:socket] = '/unix/socket'

      source.render

      source.sql_sock.should == '/unix/socket'
    end

    it "uses the builder's sql_query value" do
      builder.stub! :sql_query => 'select * from table'

      source.render

      source.sql_query.should == 'select * from table'
    end

    it "uses the builder's sql_query_range value" do
      builder.stub! :sql_query_range => 'select 0, 10 from table'

      source.render

      source.sql_query_range.should == 'select 0, 10 from table'
    end

    it "uses the builder's sql_query_info value" do
      builder.stub! :sql_query_info => 'select * from table where id = ?'

      source.render

      source.sql_query_info.should == 'select * from table where id = ?'
    end

    it "appends the builder's sql_query_pre value" do
      builder.stub! :sql_query_pre => ['Change Setting']

      source.render

      source.sql_query_pre.should == ['Change Setting']
    end

    it "adds fields with attributes to sql_field_string" do
      source.fields << double('field',
        :name => 'title', :with_attribute? => true)

      source.render

      source.sql_field_string.should include('title')
    end

    it "adds any joined or file fields"

    it "adds integer attributes to sql_attr_uint" do
      source.attributes << double('attribute',
        :type_for => :integer, :name => 'count')

      source.render

      source.sql_attr_uint.should include('count')
    end

    it "adds boolean attributes to sql_attr_bool" do
      source.attributes << double('attribute',
        :type_for => :boolean, :name => 'published')

      source.render

      source.sql_attr_bool.should include('published')
    end

    it "adds string attributes to sql_attr_string" do
      source.attributes << double('attribute',
        :type_for => :string, :name => 'name')

      source.render

      source.sql_attr_string.should include('name')
    end

    it "adds all attributes"
    it "adds other settings"
  end

  describe '#type' do
    it "is mysql when using the MySQL Adapter" do
      ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter.
        stub!(:=== => true)
      ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter.
        stub!(:=== => false)

      source.type.should == 'mysql'
    end

    it "is pgsql when using the PostgreSQL Adapter" do
      ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter.
        stub!(:=== => false)
      ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter.
        stub!(:=== => true)

      source.type.should == 'pgsql'
    end

    it "raises an exception for any other adapter" do
      ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter.
        stub!(:=== => false)
      ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter.
        stub!(:=== => false)

      lambda { source.type }.should raise_error
    end
  end
end
