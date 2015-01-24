require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::SQLSource do
  let(:model)      { double('model', :connection => connection,
    :name => 'User', :column_names => [], :inheritance_column => 'type',
    :primary_key => :id) }
  let(:connection) {
    double('connection', :instance_variable_get => db_config) }
  let(:db_config)  { {:host => 'localhost', :user => 'root',
    :database => 'default'} }
  let(:source)     { ThinkingSphinx::ActiveRecord::SQLSource.new(model,
    :position => 3) }
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

    it "has the class name attribute by default" do
      source.attributes.collect(&:name).should include('sphinx_internal_class')
    end

    it "has the internal deleted attribute by default" do
      source.attributes.collect(&:name).should include('sphinx_deleted')
    end

    it "marks the internal class attribute as a facet" do
      source.attributes.detect { |attribute|
        attribute.name == 'sphinx_internal_class'
      }.options[:facet].should be_true
    end
  end

  describe '#delta_processor' do
    let(:processor_class) { double('processor class', :try => processor) }
    let(:processor)       { double('processor') }
    let(:source)          {
      ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :delta_processor => processor_class
    }
    let(:source_with_options)    {
      ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :delta_processor => processor_class,
        :delta_options   => { :opt_key => :opt_value }
    }

    it "loads the processor with the adapter" do
      processor_class.should_receive(:try).with(:new, adapter, {}).
        and_return processor

      source.delta_processor
    end

    it "returns the given processor" do
      source.delta_processor.should == processor
    end

    it "passes given options to the processor" do
      processor_class.should_receive(:try).with(:new, adapter, {:opt_key => :opt_value})
      source_with_options.delta_processor
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

  describe '#fields' do
    it "has the internal class field by default" do
      source.fields.collect(&:name).
        should include('sphinx_internal_class_name')
    end

    it "sets the sphinx class field to use a string of the class name" do
      source.fields.detect { |field|
        field.name == 'sphinx_internal_class_name'
      }.columns.first.__name.should == "'User'"
    end

    it "uses the inheritance column if it exists for the sphinx class field" do
      adapter.stub :quoted_table_name => '"users"', :quote => '"type"'
      adapter.stub(:convert_blank) { |clause, default|
        "coalesce(nullif(#{clause}, ''), #{default})"
      }
      model.stub :column_names => ['type'], :sti_name => 'User'

      source.fields.detect { |field|
        field.name == 'sphinx_internal_class_name'
      }.columns.first.__name.
        should == "coalesce(nullif(\"users\".\"type\", ''), 'User')"
    end
  end

  describe '#name' do
    it "defaults to the model name downcased with the given position" do
      source.name.should == 'user_3'
    end

    it "allows for custom names, but adds the position suffix" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :name => 'people', :position => 2

      source.name.should == 'people_2'
    end
  end

  describe '#offset' do
    it "returns the given offset" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model, :offset => 12

      source.offset.should == 12
    end
  end

  describe '#options' do
    it "defaults to having utf8? set to false" do
      source.options[:utf8?].should be_false
    end

    it "sets utf8? to true if the database encoding is utf8" do
      db_config[:encoding] = 'utf8'

      source.options[:utf8?].should be_true
    end
  end

  describe '#render' do
    let(:builder)   { double('builder', :sql_query_pre => [],
      :sql_query_post_index => [], :sql_query => 'query',
      :sql_query_range => 'range', :sql_query_info => 'info') }
    let(:config)    { double('config', :settings => {}) }
    let(:presenter) { double('presenter', :collection_type => :uint) }
    let(:template)  { double('template', :apply => true) }

    before :each do
      ThinkingSphinx::ActiveRecord::SQLBuilder.stub! :new => builder
      ThinkingSphinx::ActiveRecord::Attribute::SphinxPresenter.stub :new => presenter
      ThinkingSphinx::ActiveRecord::SQLSource::Template.stub :new => template
      ThinkingSphinx::Configuration.stub :instance => config
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

    it "appends the builder's sql_query_pre value" do
      builder.stub! :sql_query_pre => ['Change Setting']

      source.render

      source.sql_query_pre.should == ['Change Setting']
    end

    it "appends the builder's sql_query_post_index value" do
      builder.stub! :sql_query_post_index => ['RESET DELTAS']

      source.render

      source.sql_query_post_index.should include('RESET DELTAS')
    end

    it "adds fields with attributes to sql_field_string" do
      source.fields << double('field', :name => 'title', :source_type => nil,
        :with_attribute? => true, :file? => false, :wordcount? => false)

      source.render

      source.sql_field_string.should include('title')
    end

    it "adds any joined or file fields" do
      source.fields << double('field', :name => 'title', :file? => true,
        :with_attribute? => false, :wordcount? => false,  :source_type => nil)

      source.render

      source.sql_file_field.should include('title')
    end

    it "adds wordcounted fields to sql_field_str2wordcount" do
      source.fields << double('field', :name => 'title', :source_type => nil,
        :with_attribute? => false, :file? => false, :wordcount? => true)

      source.render

      source.sql_field_str2wordcount.should include('title')
    end

    it "adds any joined fields" do
      ThinkingSphinx::ActiveRecord::PropertyQuery.stub(
        :new => double(:to_s => 'query for title')
      )
      source.fields << double('field', :name => 'title',
        :source_type => :query, :with_attribute? => false, :file? => false,
        :wordcount? => false)

      source.render

      source.sql_joined_field.should include('query for title')
    end

    it "adds integer attributes to sql_attr_uint" do
      source.attributes << double('attribute')
      presenter.stub :declaration => 'count', :collection_type => :uint

      source.render

      source.sql_attr_uint.should include('count')
    end

    it "adds boolean attributes to sql_attr_bool" do
      source.attributes << double('attribute')
      presenter.stub :declaration => 'published', :collection_type => :bool

      source.render

      source.sql_attr_bool.should include('published')
    end

    it "adds string attributes to sql_attr_string" do
      source.attributes << double('attribute')
      presenter.stub :declaration => 'name', :collection_type => :string

      source.render

      source.sql_attr_string.should include('name')
    end

    it "adds timestamp attributes to sql_attr_timestamp" do
      source.attributes << double('attribute')
      presenter.stub :declaration => 'created_at',
        :collection_type => :timestamp

      source.render

      source.sql_attr_timestamp.should include('created_at')
    end

    it "adds float attributes to sql_attr_float" do
      source.attributes << double('attribute')
      presenter.stub :declaration => 'rating', :collection_type => :float

      source.render

      source.sql_attr_float.should include('rating')
    end

    it "adds bigint attributes to sql_attr_bigint" do
      source.attributes << double('attribute')
      presenter.stub :declaration => 'super_id', :collection_type => :bigint

      source.render

      source.sql_attr_bigint.should include('super_id')
    end

    it "adds ordinal strings to sql_attr_str2ordinal" do
      source.attributes << double('attribute')
      presenter.stub :declaration => 'name', :collection_type => :str2ordinal

      source.render

      source.sql_attr_str2ordinal.should include('name')
    end

    it "adds multi-value attributes to sql_attr_multi" do
      source.attributes << double('attribute')
      presenter.stub :declaration => 'uint tag_ids from field',
        :collection_type => :multi

      source.render

      source.sql_attr_multi.should include('uint tag_ids from field')
    end

    it "adds word count attributes to sql_attr_str2wordcount" do
      source.attributes << double('attribute')
      presenter.stub :declaration => 'name', :collection_type => :str2wordcount

      source.render

      source.sql_attr_str2wordcount.should include('name')
    end

    it "adds relevant settings from thinking_sphinx.yml" do
      config.settings['mysql_ssl_cert'] = 'foo.cert'
      config.settings['morphology']     = 'stem_en' # should be ignored

      source.render

      source.mysql_ssl_cert.should == 'foo.cert'
    end
  end

  describe '#set_database_settings' do
    it "sets the sql_host setting from the model's database settings" do
      source.set_database_settings :host => '12.34.56.78'

      source.sql_host.should == '12.34.56.78'
    end

    it "defaults sql_host to localhost if the model has no host" do
      source.set_database_settings :host => nil

      source.sql_host.should == 'localhost'
    end

    it "sets the sql_user setting from the model's database settings" do
      source.set_database_settings :username => 'pat'

      source.sql_user.should == 'pat'
    end

    it "uses the user setting if username is not set in the model" do
      source.set_database_settings :username => nil, :user => 'pat'

      source.sql_user.should == 'pat'
    end

    it "sets the sql_pass setting from the model's database settings" do
      source.set_database_settings :password => 'swordfish'

      source.sql_pass.should == 'swordfish'
    end

    it "escapes hashes in the password for sql_pass" do
      source.set_database_settings :password => 'sword#fish'

      source.sql_pass.should == 'sword\#fish'
    end

    it "sets the sql_db setting from the model's database settings" do
      source.set_database_settings :database => 'rails_app'

      source.sql_db.should == 'rails_app'
    end

    it "sets the sql_port setting from the model's database settings" do
      source.set_database_settings :port => 5432

      source.sql_port.should == 5432
    end

    it "sets the sql_sock setting from the model's database settings" do
      source.set_database_settings :socket => '/unix/socket'

      source.sql_sock.should == '/unix/socket'
    end
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
