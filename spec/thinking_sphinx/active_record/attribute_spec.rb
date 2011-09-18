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
    column.stub! :to_a => [column]
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
