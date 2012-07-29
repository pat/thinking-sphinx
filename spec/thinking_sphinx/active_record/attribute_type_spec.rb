module ThinkingSphinx
  module ActiveRecord; end
end

require 'thinking_sphinx/active_record/attribute_type'

describe ThinkingSphinx::ActiveRecord::AttributeType do
  let(:type) {
    ThinkingSphinx::ActiveRecord::AttributeType.new attribute, model }
  let(:attribute) { double('attribute', :columns => [column], :options => {}) }
  let(:model)     { double('model', :columns => [db_column]) }
  let(:column)    { double('column', :__name => :created_at, :string? => false,
    :__stack => []) }
  let(:db_column) { double('column', :name => 'created_at',
    :type => :integer) }

  describe '#multi?' do
    let(:association) { double('association', :klass => double) }

    before :each do
      column.__stack << :foo

      model.stub :reflect_on_association => association
    end

    it "returns true if there are has_many associations" do
      association.stub :macro => :has_many

      type.should be_multi
    end

    it "returns true if there are has_and_belongs_to_many associations" do
      association.stub :macro => :has_and_belongs_to_many

      type.should be_multi
    end

    it "returns false if there are no associations" do
      column.__stack.clear

      type.should_not be_multi
    end

    it "returns false if there are only belongs_to associations" do
      association.stub :macro => :belongs_to

      type.should_not be_multi
    end

    it "returns false if there are only has_one associations" do
      association.stub :macro => :has_one

      type.should_not be_multi
    end

    it "returns true if deeper associations have many" do
      column.__stack << :bar
      deep_association = double(:klass => double, :macro => :has_many)
      association.stub :macro => :belongs_to,
        :klass => double(:reflect_on_association => deep_association)

      type.should be_multi
    end

    it "respects the provided setting" do
      attribute.options[:multi] = true

      type.should be_multi
    end
  end

  describe '#type' do
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

    it "respects provided type setting" do
      attribute.options[:type] = :timestamp

      type.type.should == :timestamp
    end
  end
end
