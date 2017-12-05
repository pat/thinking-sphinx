# frozen_string_literal: true

module ThinkingSphinx
  class Search; end
end

require 'active_support/core_ext/object/blank'
require './lib/thinking_sphinx/search/query'

describe ThinkingSphinx::Search::Query do
  before :each do
    stub_const 'ThinkingSphinx::Query', double(wildcard: '')
  end

  describe '#to_s' do
    it "passes through the keyword as provided" do
      query = ThinkingSphinx::Search::Query.new 'pancakes'

      expect(query.to_s).to eq('pancakes')
    end

    it "pairs fields and keywords for given conditions" do
      query = ThinkingSphinx::Search::Query.new '', :title => 'pancakes'

      expect(query.to_s).to eq('@title pancakes')
    end

    it "combines both keywords and conditions" do
      query = ThinkingSphinx::Search::Query.new 'tasty', :title => 'pancakes'

      expect(query.to_s).to eq('tasty @title pancakes')
    end

    it "automatically stars keywords if requested" do
      expect(ThinkingSphinx::Query).to receive(:wildcard).with('cake', true).
        and_return('*cake*')

      ThinkingSphinx::Search::Query.new('cake', {}, true).to_s
    end

    it "automatically stars condition keywords if requested" do
      expect(ThinkingSphinx::Query).to receive(:wildcard).with('pan', true).
        and_return('*pan*')

      ThinkingSphinx::Search::Query.new('', {:title => 'pan'}, true).to_s
    end

    it "does not star the sphinx_internal_class field keyword" do
      query = ThinkingSphinx::Search::Query.new '',
        {:sphinx_internal_class_name => 'article'}, true

      expect(query.to_s).to eq('@sphinx_internal_class_name article')
    end

    it "handles null values by removing them from the conditions hash" do
      query = ThinkingSphinx::Search::Query.new '', :title => nil

      expect(query.to_s).to eq('')
    end

    it "handles empty string values by removing them from the conditions hash" do
      query = ThinkingSphinx::Search::Query.new '', :title => ''

      expect(query.to_s).to eq('')
    end

    it "handles nil queries" do
      query = ThinkingSphinx::Search::Query.new nil, {}

      expect(query.to_s).to eq('')
    end

    it "allows mixing of blank and non-blank conditions" do
      query = ThinkingSphinx::Search::Query.new 'tasty', :title => 'pancakes',
        :ingredients => nil

      expect(query.to_s).to eq('tasty @title pancakes')
    end

    it "handles multiple fields for a single condition" do
      query = ThinkingSphinx::Search::Query.new '',
        [:title, :content] => 'pancakes'

      expect(query.to_s).to eq('@(title,content) pancakes')
    end
  end
end
