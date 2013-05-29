module ThinkingSphinx
  class Search; end
end

require 'active_support/core_ext/object/blank'
require './lib/thinking_sphinx/search/query'

describe ThinkingSphinx::Search::Query do
  describe '#to_s' do
    it "passes through the keyword as provided" do
      query = ThinkingSphinx::Search::Query.new 'pancakes'

      query.to_s.should == 'pancakes'
    end

    it "pairs fields and keywords for given conditions" do
      query = ThinkingSphinx::Search::Query.new '', :title => 'pancakes'

      query.to_s.should == '@title pancakes'
    end

    it "combines both keywords and conditions" do
      query = ThinkingSphinx::Search::Query.new 'tasty', :title => 'pancakes'

      query.to_s.should == 'tasty @title pancakes'
    end

    it "automatically stars keywords if requested" do
      query = ThinkingSphinx::Search::Query.new 'cake', {}, true

      query.to_s.should == '*cake*'
    end

    it "automatically stars condition keywords if requested" do
      query = ThinkingSphinx::Search::Query.new '', {:title => 'pan'}, true

      query.to_s.should == '@title *pan*'
    end

    it "does not star the sphinx_internal_class field keyword" do
      query = ThinkingSphinx::Search::Query.new '',
        {:sphinx_internal_class_name => 'article'}, true

      query.to_s.should == '@sphinx_internal_class_name article'
    end

    it "handles null values by removing them from the conditions hash" do
      query = ThinkingSphinx::Search::Query.new '', :title => nil

      query.to_s.should == ''
    end

    it "handles empty string values by removing them from the conditions hash" do
      query = ThinkingSphinx::Search::Query.new '', :title => ''

      query.to_s.should == ''
    end

    it "allows mixing of blank and non-blank conditions" do
      query = ThinkingSphinx::Search::Query.new 'tasty', :title => 'pancakes',
        :ingredients => nil

      query.to_s.should == 'tasty @title pancakes'
    end
  end
end
