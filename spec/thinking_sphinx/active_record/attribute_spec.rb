require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Attribute do
  let(:attribute) { ThinkingSphinx::ActiveRecord::Attribute.new column }
  let(:column)    { double('column', :__name => :created_at) }

  describe 'to_group_sql' do
    it "returns the column name as a string" do
      attribute.to_group_sql.should == 'created_at'
    end
  end

  describe 'to_select_sql' do
    it "returns the column name as a string" do
      attribute.to_select_sql.should == 'created_at'
    end

    it "returns the column name with an alias when provided" do
      attribute = ThinkingSphinx::ActiveRecord::Attribute.new column,
        :as => :creation_timestamp

      attribute.to_select_sql.should == 'created_at AS creation_timestamp'
    end
  end
end
