# frozen_string_literal: true

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
    :position => 3, :primary_key => model.primary_key || :id ) }
  let(:adapter)    { double('adapter') }

  before :each do
    allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter).
      to receive_messages(:=== => true)
    allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters).
      to receive_messages(:adapter_for => adapter)
  end

  describe '#adapter' do
    it "returns a database adapter for the model" do
      expect(ThinkingSphinx::ActiveRecord::DatabaseAdapters).
        to receive(:adapter_for).with(model).and_return(adapter)

      expect(source.adapter).to eq(adapter)
    end
  end

  describe '#add_attribute' do
    let(:attribute) { double('attribute', name: 'my_attribute') }

    it "appends attributes to the collection" do
      source.add_attribute attribute

      expect(source.attributes.collect(&:name)).to include('my_attribute')
    end

    it "replaces attributes with the same name" do
      source.add_attribute double('attribute', name: 'my_attribute')
      source.add_attribute attribute

      matching = source.attributes.select { |attr| attr.name == attribute.name }

      expect(matching).to eq([attribute])
    end
  end

  describe '#add_field' do
    let(:field) { double('field', name: 'my_field') }

    it "appends fields to the collection" do
      source.add_field field

      expect(source.fields.collect(&:name)).to include('my_field')
    end

    it "replaces fields with the same name" do
      source.add_field double('field', name: 'my_field')
      source.add_field field

      matching = source.fields.select { |fld| fld.name == field.name }

      expect(matching).to eq([field])
    end
  end

  describe '#attributes' do
    it "has the internal id attribute by default" do
      expect(source.attributes.collect(&:name)).to include('sphinx_internal_id')
    end

    it "has the class name attribute by default" do
      expect(source.attributes.collect(&:name)).to include('sphinx_internal_class')
    end

    it "has the internal deleted attribute by default" do
      expect(source.attributes.collect(&:name)).to include('sphinx_deleted')
    end

    it "marks the internal class attribute as a facet" do
      expect(source.attributes.detect { |attribute|
        attribute.name == 'sphinx_internal_class'
      }.options[:facet]).to be_truthy
    end
  end

  describe '#delta_processor' do
    let(:processor_class) { double('processor class', :try => processor) }
    let(:processor)       { double('processor') }
    let(:source)          {
      ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :delta_processor => processor_class,
        :primary_key => model.primary_key || :id
    }
    let(:source_with_options)    {
      ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :delta_processor => processor_class,
        :delta_options   => { :opt_key => :opt_value },
        :primary_key => model.primary_key || :id
    }

    it "loads the processor with the adapter" do
      expect(processor_class).to receive(:try).with(:new, adapter, {}).
        and_return processor

      source.delta_processor
    end

    it "returns the given processor" do
      expect(source.delta_processor).to eq(processor)
    end

    it "passes given options to the processor" do
      expect(processor_class).to receive(:try).with(:new, adapter, {:opt_key => :opt_value})
      source_with_options.delta_processor
    end
  end

  describe '#delta?' do
    it "returns the given delta setting" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :delta? => true,
        :primary_key => model.primary_key || :id

      expect(source).to be_a_delta
    end
  end

  describe '#disable_range?' do
    it "returns the given range setting" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :disable_range? => true,
        :primary_key => model.primary_key || :id

      expect(source.disable_range?).to be_truthy
    end
  end

  describe '#fields' do
    it "has the internal class field by default" do
      expect(source.fields.collect(&:name)).
        to include('sphinx_internal_class_name')
    end

    it "sets the sphinx class field to use a string of the class name" do
      expect(source.fields.detect { |field|
        field.name == 'sphinx_internal_class_name'
      }.columns.first.__name).to eq("'User'")
    end

    it "uses the inheritance column if it exists for the sphinx class field" do
      allow(adapter).to receive_messages :quoted_table_name => '"users"', :quote => '"type"'
      allow(adapter).to receive(:convert_blank) { |clause, default|
        "coalesce(nullif(#{clause}, ''), #{default})"
      }
      allow(model).to receive_messages :column_names => ['type'], :sti_name => 'User'

      expect(source.fields.detect { |field|
        field.name == 'sphinx_internal_class_name'
      }.columns.first.__name).
        to eq("coalesce(nullif(\"users\".\"type\", ''), 'User')")
    end
  end

  describe '#name' do
    it "defaults to the model name downcased with the given position" do
      expect(source.name).to eq('user_3')
    end

    it "allows for custom names, but adds the position suffix" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :name => 'people', :position => 2, :primary_key => model.primary_key || :id

      expect(source.name).to eq('people_2')
    end
  end

  describe '#offset' do
    it "returns the given offset" do
      source = ThinkingSphinx::ActiveRecord::SQLSource.new model,
        :offset => 12, :primary_key => model.primary_key || :id

      expect(source.offset).to eq(12)
    end
  end

  describe '#options' do
    it "defaults to having utf8? set to false" do
      expect(source.options[:utf8?]).to be_falsey
    end

    it "sets utf8? to true if the database encoding is utf8" do
      db_config[:encoding] = 'utf8'

      expect(source.options[:utf8?]).to be_truthy
    end

    it "sets utf8? to true if the database encoding starts with utf8" do
      db_config[:encoding] = 'utf8mb4'

      expect(source.options[:utf8?]).to be_truthy
    end

    describe "#primary key" do
      let(:model)  { double('model', :connection => connection,
                           :name => 'User', :column_names => [], :inheritance_column => 'type') }
      let(:source) { ThinkingSphinx::ActiveRecord::SQLSource.new(model,
                           :position => 3, :primary_key => :custom_key) }
      let(:template) { ThinkingSphinx::ActiveRecord::SQLSource::Template.new(source) }

      it 'template should allow primary key from options' do
        template.apply
        template.source.attributes.collect(&:columns) == :custom_key
      end
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
      allow(ThinkingSphinx::ActiveRecord::SQLBuilder).to receive_messages :new => builder
      allow(ThinkingSphinx::ActiveRecord::Attribute::SphinxPresenter).to receive_messages :new => presenter
      allow(ThinkingSphinx::ActiveRecord::SQLSource::Template).to receive_messages :new => template
      allow(ThinkingSphinx::Configuration).to receive_messages :instance => config
    end

    it "uses the builder's sql_query value" do
      allow(builder).to receive_messages :sql_query => 'select * from table'

      source.render

      expect(source.sql_query).to eq('select * from table')
    end

    it "uses the builder's sql_query_range value" do
      allow(builder).to receive_messages :sql_query_range => 'select 0, 10 from table'

      source.render

      expect(source.sql_query_range).to eq('select 0, 10 from table')
    end

    it "appends the builder's sql_query_pre value" do
      allow(builder).to receive_messages :sql_query_pre => ['Change Setting']

      source.render

      expect(source.sql_query_pre).to eq(['Change Setting'])
    end

    it "adds fields with attributes to sql_field_string" do
      source.fields << double('field', :name => 'title', :source_type => nil,
        :with_attribute? => true, :file? => false, :wordcount? => false)

      source.render

      expect(source.sql_field_string).to include('title')
    end

    it "adds any joined or file fields" do
      source.fields << double('field', :name => 'title', :file? => true,
        :with_attribute? => false, :wordcount? => false,  :source_type => nil)

      source.render

      expect(source.sql_file_field).to include('title')
    end

    it "adds wordcounted fields to sql_field_str2wordcount" do
      source.fields << double('field', :name => 'title', :source_type => nil,
        :with_attribute? => false, :file? => false, :wordcount? => true)

      source.render

      expect(source.sql_field_str2wordcount).to include('title')
    end

    it "adds any joined fields" do
      allow(ThinkingSphinx::ActiveRecord::PropertyQuery).to receive_messages(
        :new => double(:to_s => 'query for title')
      )
      source.fields << double('field', :name => 'title',
        :source_type => :query, :with_attribute? => false, :file? => false,
        :wordcount? => false)

      source.render

      expect(source.sql_joined_field).to include('query for title')
    end

    it "adds integer attributes to sql_attr_uint" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'count', :collection_type => :uint

      source.render

      expect(source.sql_attr_uint).to include('count')
    end

    it "adds boolean attributes to sql_attr_bool" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'published', :collection_type => :bool

      source.render

      expect(source.sql_attr_bool).to include('published')
    end

    it "adds string attributes to sql_attr_string" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'name', :collection_type => :string

      source.render

      expect(source.sql_attr_string).to include('name')
    end

    it "adds timestamp attributes to sql_attr_uint" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'created_at',
        :collection_type => :uint

      source.render

      expect(source.sql_attr_uint).to include('created_at')
    end

    it "adds float attributes to sql_attr_float" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'rating', :collection_type => :float

      source.render

      expect(source.sql_attr_float).to include('rating')
    end

    it "adds bigint attributes to sql_attr_bigint" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'super_id', :collection_type => :bigint

      source.render

      expect(source.sql_attr_bigint).to include('super_id')
    end

    it "adds ordinal strings to sql_attr_str2ordinal" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'name', :collection_type => :str2ordinal

      source.render

      expect(source.sql_attr_str2ordinal).to include('name')
    end

    it "adds multi-value attributes to sql_attr_multi" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'uint tag_ids from field',
        :collection_type => :multi

      source.render

      expect(source.sql_attr_multi).to include('uint tag_ids from field')
    end

    it "adds word count attributes to sql_attr_str2wordcount" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'name', :collection_type => :str2wordcount

      source.render

      expect(source.sql_attr_str2wordcount).to include('name')
    end

    it "adds json attributes to sql_attr_json" do
      source.attributes << double('attribute')
      allow(presenter).to receive_messages :declaration => 'json', :collection_type => :json

      source.render

      expect(source.sql_attr_json).to include('json')
    end

    it "adds relevant settings from thinking_sphinx.yml" do
      config.settings['mysql_ssl_cert'] = 'foo.cert'
      config.settings['morphology']     = 'stem_en' # should be ignored

      source.render

      expect(source.mysql_ssl_cert).to eq('foo.cert')
    end
  end

  describe '#set_database_settings' do
    it "sets the sql_host setting from the model's database settings" do
      source.set_database_settings :host => '12.34.56.78'

      expect(source.sql_host).to eq('12.34.56.78')
    end

    it "defaults sql_host to localhost if the model has no host" do
      source.set_database_settings :host => nil

      expect(source.sql_host).to eq('localhost')
    end

    it "sets the sql_user setting from the model's database settings" do
      source.set_database_settings :username => 'pat'

      expect(source.sql_user).to eq('pat')
    end

    it "uses the user setting if username is not set in the model" do
      source.set_database_settings :username => nil, :user => 'pat'

      expect(source.sql_user).to eq('pat')
    end

    it "sets the sql_pass setting from the model's database settings" do
      source.set_database_settings :password => 'swordfish'

      expect(source.sql_pass).to eq('swordfish')
    end

    it "escapes hashes in the password for sql_pass" do
      source.set_database_settings :password => 'sword#fish'

      expect(source.sql_pass).to eq('sword\#fish')
    end

    it "sets the sql_db setting from the model's database settings" do
      source.set_database_settings :database => 'rails_app'

      expect(source.sql_db).to eq('rails_app')
    end

    it "sets the sql_port setting from the model's database settings" do
      source.set_database_settings :port => 5432

      expect(source.sql_port).to eq(5432)
    end

    it "sets the sql_sock setting from the model's database settings" do
      source.set_database_settings :socket => '/unix/socket'

      expect(source.sql_sock).to eq('/unix/socket')
    end

    it "sets the mysql_ssl_cert from the model's database settings" do
      source.set_database_settings :sslcert => '/path/to/cert.pem'

      expect(source.mysql_ssl_cert).to  eq '/path/to/cert.pem'
    end

    it "sets the mysql_ssl_key from the model's database settings" do
      source.set_database_settings :sslkey => '/path/to/key.pem'

      expect(source.mysql_ssl_key).to  eq '/path/to/key.pem'
    end

    it "sets the mysql_ssl_ca from the model's database settings" do
      source.set_database_settings :sslca => '/path/to/ca.pem'

      expect(source.mysql_ssl_ca).to  eq '/path/to/ca.pem'
    end
  end

  describe '#type' do
    it "is mysql when using the MySQL Adapter" do
      allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter).
        to receive_messages(:=== => true)
      allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter).
        to receive_messages(:=== => false)

      expect(source.type).to eq('mysql')
    end

    it "is pgsql when using the PostgreSQL Adapter" do
      allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter).
        to receive_messages(:=== => false)
      allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter).
        to receive_messages(:=== => true)

      expect(source.type).to eq('pgsql')
    end

    it "raises an exception for any other adapter" do
      allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters::MySQLAdapter).
        to receive_messages(:=== => false)
      allow(ThinkingSphinx::ActiveRecord::DatabaseAdapters::PostgreSQLAdapter).
        to receive_messages(:=== => false)

      expect { source.type }.to raise_error(
        ThinkingSphinx::UnknownDatabaseAdapter
      )
    end
  end
end
