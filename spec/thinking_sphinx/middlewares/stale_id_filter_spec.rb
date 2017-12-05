# frozen_string_literal: true

module ThinkingSphinx
  module Middlewares; end
  class  Search; end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/stale_id_filter'
require 'thinking_sphinx/search/stale_ids_exception'

describe ThinkingSphinx::Middlewares::StaleIdFilter do
  let(:app)        { double('app', :call => true) }
  let(:middleware) { ThinkingSphinx::Middlewares::StaleIdFilter.new app }
  let(:context)    { {:raw => [], :results => []} }
  let(:search)     { double('search', :options => {}) }

  describe '#call' do
    before :each do
      allow(context).to receive_messages :search => search
    end

    context 'one stale ids exception' do
      before :each do
        allow(app).to receive(:call) do
          @calls ||= 0
          @calls += 1
          raise ThinkingSphinx::Search::StaleIdsException.new([12], context) if @calls == 1
        end
      end

      it "appends the ids to the without_ids filter" do
        middleware.call [context]

        expect(search.options[:without_ids]).to eq([12])
      end

      it "respects existing without_ids filters" do
        search.options[:without_ids] = [11]

        middleware.call [context]

        expect(search.options[:without_ids]).to eq([11, 12])
      end
    end

    context  'two stale ids exceptions' do
      before :each do
        allow(app).to receive(:call) do
          @calls ||= 0
          @calls += 1
          raise ThinkingSphinx::Search::StaleIdsException.new([12], context) if @calls == 1
          raise ThinkingSphinx::Search::StaleIdsException.new([13], context) if @calls == 2
        end
      end

      it "appends the ids to the without_ids filter" do
        middleware.call [context]

        expect(search.options[:without_ids]).to eq([12, 13])
      end

      it "respects existing without_ids filters" do
        search.options[:without_ids] = [11]

        middleware.call [context]

        expect(search.options[:without_ids]).to eq([11, 12, 13])
      end
    end

    context 'three stale ids exceptions' do
      before :each do
        allow(app).to receive(:call) do
          @calls ||= 0
          @calls += 1

          raise ThinkingSphinx::Search::StaleIdsException.new([12], context) if @calls == 1
          raise ThinkingSphinx::Search::StaleIdsException.new([13], context) if @calls == 2
          raise ThinkingSphinx::Search::StaleIdsException.new([14], context) if @calls == 3
        end
      end

      it "raises the final stale ids exceptions" do
        expect {
          middleware.call [context]
        }.to raise_error(ThinkingSphinx::Search::StaleIdsException) { |err|
          expect(err.ids).to eq([14])
        }
      end
    end

    context  'stale ids exceptions with multiple contexts' do
      let(:context2) { {:raw => [], :results => []} }
      let(:search2) { double('search2', :options => {}) }
      before :each do
        allow(context2).to receive_messages :search => search2
        allow(app).to receive(:call) do
          @calls ||= 0
          @calls += 1
          raise ThinkingSphinx::Search::StaleIdsException.new([12], context2) if @calls == 1
        end
      end

      it "appends the ids to the without_ids filter in the correct context" do
        middleware.call [context, context2]
        expect(search.options[:without_ids]).to eq(nil)
        expect(search2.options[:without_ids]).to eq([12])
      end
    end

  end
end
