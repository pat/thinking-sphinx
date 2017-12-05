# frozen_string_literal: true

module ThinkingSphinx
  module Middlewares; end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/glazier'

describe ThinkingSphinx::Middlewares::Glazier do
  let(:app)           { double('app', :call => true) }
  let(:middleware)    { ThinkingSphinx::Middlewares::Glazier.new app }
  let(:context)       { {:results => [result], :indices => [index],
    :meta => {}, :raw => [raw_result], :panes => []} }
  let(:result)        { double('result', :id => 10,
    :class => double(:name => 'Article')) }
  let(:index)         { double('index', :name => 'foo_core') }
  let(:search)        { double('search', :options => {}) }
  let(:glazed_result) { double('glazed result') }
  let(:raw_result) {
    {'sphinx_internal_class' => 'Article', 'sphinx_internal_id' => 10} }

  describe '#call' do
    before :each do
      stub_const 'ThinkingSphinx::Search::Glaze', double(:new => glazed_result)

      allow(context).to receive_messages :search => search
    end

    context 'No panes provided' do
      before :each do
        context[:panes].clear
      end

      it "leaves the results as they are" do
        middleware.call [context]

        expect(context[:results]).to eq([result])
      end
    end

    context 'Panes provided' do
      let(:pane_class) { double('pane class') }

      before :each do
        context[:panes] << pane_class
      end

      it "replaces each result with a glazed version" do
        middleware.call [context]

        expect(context[:results]).to eq([glazed_result])
      end

      it "creates a glazed result for each result" do
        expect(ThinkingSphinx::Search::Glaze).to receive(:new).
          with(context, result, raw_result, [pane_class]).
          and_return(glazed_result)

        middleware.call [context]
      end
    end
  end
end
