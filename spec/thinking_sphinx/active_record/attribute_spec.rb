require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Attribute do
  let(:attribute)    { ThinkingSphinx::ActiveRecord::Attribute.new column }
  let(:column)       {
    double('column', :__name => :created_at, :string? => false, :__stack => [])
  }
  let(:associations) { double('associations', :alias_for => 'articles') }
  let(:source)       { double('source', :model => model, :adapter => adapter) }
  let(:model)        { double('model', :columns => [db_column]) }
  let(:db_column)    {
    double('column', :name => 'created_at', :type => :integer)
  }
  let(:adapter)      { double('adapter') }

  before :each do
    adapter.stub :cast_to_timestamp do |clause|
      "UNIX_TIMESTAMP(#{clause})"
    end
  end

  describe '#to_group_sql' do
    it "returns the column name as a string" do
      attribute.to_group_sql(associations).should == 'articles.created_at'
    end

    it "gets the column's table alias from the associations object" do
      column.stub!(:__stack => [:users, :posts])

      associations.should_receive(:alias_for).with([:users, :posts]).
        and_return('posts')

      attribute.to_group_sql(associations)
    end

    it "returns nil if the column is a string" do
      column.stub!(:string? => true)

      attribute.to_group_sql(associations).should be_nil
    end
  end

  describe '#to_select_sql' do
    it "returns the column name as a string" do
      attribute.to_select_sql(associations, source).
        should == 'articles.created_at AS created_at'
    end

    it "gets the column's table alias from the associations object" do
      column.stub!(:__stack => [:users, :posts])

      associations.should_receive(:alias_for).with([:users, :posts]).
        and_return('posts')

      attribute.to_select_sql(associations, source)
    end

    it "returns the column name with an alias when provided" do
      attribute = ThinkingSphinx::ActiveRecord::Attribute.new column,
        :as => :creation_timestamp

      attribute.to_select_sql(associations, source).
        should == 'articles.created_at AS creation_timestamp'
    end

    it "ensures datetime attributes are converted to timestamps" do
      attribute = ThinkingSphinx::ActiveRecord::Attribute.new column,
        :type => :timestamp

      attribute.to_select_sql(associations, source).
        should == 'UNIX_TIMESTAMP(articles.created_at) AS created_at'
    end
  end

  describe '#type_for' do
    it "returns the type option provided" do
      attribute = ThinkingSphinx::ActiveRecord::Attribute.new column,
        :type => :datetime

      attribute.type_for(model).should == :datetime
    end

    it "detects integer types from the database" do
      db_column.stub!(:type => :integer)

      attribute.type_for(model).should == :integer
    end

    it "detects boolean types from the database" do
      db_column.stub!(:type => :boolean)

      attribute.type_for(model).should == :boolean
    end

    it "detects datetime types from the database as timestamps" do
      db_column.stub!(:type => :datetime)

      attribute.type_for(model).should == :timestamp
    end
  end
end
