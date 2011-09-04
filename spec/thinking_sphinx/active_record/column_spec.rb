require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Column do
  describe '#__name' do
    it "returns the top item" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:content)
      column.__name.should == :content
    end
  end
end
