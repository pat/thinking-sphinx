module ThinkingSphinx
  module ActiveRecord; end
end

require 'thinking_sphinx/active_record/attribute_type'

describe ThinkingSphinx::ActiveRecord::AttributeType do
  let(:type) {
    ThinkingSphinx::ActiveRecord::AttributeType.new attribute, model }
  let(:attribute) { double('attribute', :columns => [column], :options => {}) }
  let(:model)     { double('model', :columns => [db_column]) }
  let(:column)    {
    double('column', :__name => :created_at, :string? => false, :__stack => [])
  }
  let(:db_column) {
    double('column', :name => 'created_at', :type => :integer) }

  describe '#type_for' do
    it "returns the type option provided" do
      attribute.options[:type] = :datetime

      type.type.should == :datetime
    end

    it "detects integer types from the database" do
      db_column.stub!(:type => :integer)

      type.type.should == :integer
    end

    it "detects boolean types from the database" do
      db_column.stub!(:type => :boolean)

      type.type.should == :boolean
    end

    it "detects datetime types from the database as timestamps" do
      db_column.stub!(:type => :datetime)

      type.type.should == :timestamp
    end

    it "detects date types from the database as timestamps" do
      db_column.stub!(:type => :date)

      type.type.should == :timestamp
    end

    it "detects string types from the database" do
      db_column.stub!(:type => :string)

      type.type.should == :string
    end

    it "detects text types from the database as strings" do
      db_column.stub!(:type => :text)

      type.type.should == :string
    end

    it "detects float types from the database" do
      db_column.stub!(:type => :float)

      type.type.should == :float
    end

    it "detects decimal types from the database as floats" do
      db_column.stub!(:type => :decimal)

      type.type.should == :float
    end
  end
end
