require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Field do
  let(:field)  { ThinkingSphinx::ActiveRecord::Field.new column }
  let(:column) { double('column', :__name => :title) }

  describe '#to_group_sql' do
    it "returns the column name as a string" do
      field.to_group_sql.should == 'title'
    end
  end

  describe '#to_select_sql' do
    it "returns the column name as a string" do
      field.to_select_sql.should == 'title'
    end
  end
end
