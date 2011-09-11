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

  describe '#type' do
    it "returns an integer by default" do
      attribute.type.should == :integer
    end

    it "returns the type option provided" do
      attribute = ThinkingSphinx::ActiveRecord::Attribute.new column,
        :type => :datetime

      attribute.type.should == :datetime
    end
  end
end
