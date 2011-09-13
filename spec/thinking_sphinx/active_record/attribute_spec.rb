require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Attribute do
  let(:attribute) { ThinkingSphinx::ActiveRecord::Attribute.new column }
  let(:column)    {
    double('column', :__name => :created_at, :string? => false)
  }

  describe '#to_group_sql' do
    it "returns the column name as a string" do
      attribute.to_group_sql.should == 'created_at'
    end

    it "returns nil if the column is a string" do
      column.stub!(:string? => true)

      attribute.to_group_sql.should be_nil
    end
  end

  describe '#to_select_sql' do
    it "returns the column name as a string" do
      attribute.to_select_sql.should == 'created_at'
    end

    it "returns the column name with an alias when provided" do
      attribute = ThinkingSphinx::ActiveRecord::Attribute.new column,
        :as => :creation_timestamp

      attribute.to_select_sql.should == 'created_at AS creation_timestamp'
    end
  end

  describe '#type_for' do
    let(:model)     { double('model', :columns => [db_column]) }
    let(:db_column) { double('column', :name => 'created_at') }

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
  end
end
