module ThinkingSphinx
  class Search; end
end

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
        {:sphinx_internal_class => 'article'}, true

      query.to_s.should == '@sphinx_internal_class article'
    end
  end
end
