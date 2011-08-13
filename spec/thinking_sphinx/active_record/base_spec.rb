require 'spec_helper'

class PlaceholderModel
  extend ThinkingSphinx::ActiveRecord::Base
end

describe ThinkingSphinx::ActiveRecord::Base do
  describe '.search' do
    it "returns a new search object" do
      PlaceholderModel.search.should be_a(ThinkingSphinx::Search)
    end

    it "passes through arguments to the search object initializer" do
      ThinkingSphinx::Search.should_receive(:new).with('pancakes')

      PlaceholderModel.search 'pancakes'
    end

    it "scopes the search to a given model"
  end
end
