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

    it "treats escapes as word characters" do
      query = ThinkingSphinx::Search::Query.new '', {:title => 'sauce\\@pan'},
        true

      query.to_s.should == '@title *sauce\\@pan*'
    end

    it "does not star manually provided field tags" do
      query = ThinkingSphinx::Search::Query.new "@title pan", {}, true

      query.to_s.should == "@title *pan*"
    end

    it "does not star manually provided arrays of field tags" do
      query = ThinkingSphinx::Search::Query.new "@(title, body) pan", {}, true

      query.to_s.should == "@(title, body) *pan*"
    end

    it "stars keywords that begin with an escaped @" do
      query = ThinkingSphinx::Search::Query.new "\\@pan", {}, true

      query.to_s.should == "*\\@pan*"
    end

    it "ignores escaped slashes" do
      query = ThinkingSphinx::Search::Query.new "\\/\\/pan", {}, true

      query.to_s.should == "\\/\\/*pan*"
    end

    it "separates escaping from the end of words" do
      query = ThinkingSphinx::Search::Query.new "\\(913\\)", {}, true

      query.to_s.should == "\\(*913*\\)"
    end

    it "does not star quorum operators" do
      query = ThinkingSphinx::Search::Query.new "foo/3", {}, true

      query.to_s.should == "*foo*/3"
    end

    it "does not star proximity operators or quoted strings" do
      query = ThinkingSphinx::Search::Query.new %q{"hello world"~3}, {}, true

      query.to_s.should == %q{"hello world"~3}
    end

    it "handles null values by removing them from the conditions hash" do
      query = ThinkingSphinx::Search::Query.new '', :title => nil

      query.to_s.should == ''
    end

    it "handles empty string values by removing them from the conditions hash" do
      query = ThinkingSphinx::Search::Query.new '', :title => ''

      query.to_s.should == ''
    end

    it "handles nil queries" do
      query = ThinkingSphinx::Search::Query.new nil, {}

      query.to_s.should == ''
    end

    it "handles nil queries when starring" do
      query = ThinkingSphinx::Search::Query.new nil, {}, true

      query.to_s.should == ''
    end

    it "allows mixing of blank and non-blank conditions" do
      query = ThinkingSphinx::Search::Query.new 'tasty', :title => 'pancakes',
        :ingredients => nil

      query.to_s.should == 'tasty @title pancakes'
    end
  end
end
