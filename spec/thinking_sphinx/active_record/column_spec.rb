require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Column do
  describe '#__name' do
    it "returns the top item" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:content)
      column.__name.should == :content
    end
  end

  describe '#string?' do
    it "is true when the name is a string" do
      column = ThinkingSphinx::ActiveRecord::Column.new('content')
      column.should be_a_string
    end

    it "is false when the name is a symbol" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:content)
      column.should_not be_a_string
    end
  end
end
