module ThinkingSphinx
  module Middlewares; end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/glazier'

describe ThinkingSphinx::Middlewares::Glazier do
  let(:app)           { double('app', :call => true) }
  let(:middleware)    { ThinkingSphinx::Middlewares::Glazier.new app }
  let(:context)       { {:results => [result], :indices => [index],
    :meta => {}, :raw => [raw_result]} }
  let(:result)        { double('result', :id => 10,
    :class => double(:name => 'Article')) }
  let(:index)         { double('index', :name => 'foo_core') }
  let(:search)        { double('search', :options => {}) }
  let(:excerpter)     { double('excerpter') }
  let(:glazed_result) { double('glazed result') }
  let(:raw_result) {
    {'sphinx_internal_class_attr' => 'Article', 'sphinx_internal_id' => 10} }

  describe '#call' do

    before :each do
      stub_const 'ThinkingSphinx::Search::Glaze', double(:new => glazed_result)
      stub_const 'ThinkingSphinx::Excerpter',     double(:new => excerpter)

      context.stub :search => search
    end

    it "replaces each result with a glazed version" do
      middleware.call context

      context[:results].should == [glazed_result]
    end

    it "creates a glazed result for each result" do
      ThinkingSphinx::Search::Glaze.should_receive(:new).
        with(result, excerpter, raw_result).and_return(glazed_result)

      middleware.call context
    end

    it "creates an excerpter with the first index and all keywords" do
      context[:indices] = [double(:name => 'alpha'), double(:name => 'beta')]
      context[:meta]['keyword[0]'] = 'foo'
      context[:meta]['keyword[1]'] = 'bar'

      ThinkingSphinx::Excerpter.should_receive(:new).
        with('alpha', 'foo bar', anything).and_return(excerpter)

      middleware.call context
    end

    it "passes through excerpts options" do
      search.options[:excerpts] = {:before_match => 'foo'}

      ThinkingSphinx::Excerpter.should_receive(:new).
        with(anything, anything, :before_match => 'foo').and_return(excerpter)

      middleware.call context
    end
  end
end
