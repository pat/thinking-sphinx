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
      context.stub :search => search, :log => true
    end

    context 'one stale ids exception' do
      before :each do
        app.stub(:call) do
          @calls ||= 0
          @calls += 1
          raise ThinkingSphinx::Search::StaleIdsException, [12] if @calls == 1
        end
      end

      it "appends the ids to the without_ids filter" do
        middleware.call [context]

        search.options[:without_ids].should == [12]
      end

      it "respects existing without_ids filters" do
        search.options[:without_ids] = [11]

        middleware.call [context]

        search.options[:without_ids].should == [11, 12]
      end
    end

    context  'two stale ids exceptions' do
      before :each do
        app.stub(:call) do
          @calls ||= 0
          @calls += 1
          raise ThinkingSphinx::Search::StaleIdsException, [12] if @calls == 1
          raise ThinkingSphinx::Search::StaleIdsException, [13] if @calls == 2
        end
      end

      it "appends the ids to the without_ids filter" do
        middleware.call [context]

        search.options[:without_ids].should == [12, 13]
      end

      it "respects existing without_ids filters" do
        search.options[:without_ids] = [11]

        middleware.call [context]

        search.options[:without_ids].should == [11, 12, 13]
      end
    end

    context 'three stale ids exceptions' do
      before :each do
        app.stub(:call) do
          @calls ||= 0
          @calls += 1

          raise ThinkingSphinx::Search::StaleIdsException, [12] if @calls == 1
          raise ThinkingSphinx::Search::StaleIdsException, [13] if @calls == 2
          raise ThinkingSphinx::Search::StaleIdsException, [14] if @calls == 3
        end
      end

      it "raises the final stale ids exceptions" do
        lambda {
          middleware.call [context]
        }.should raise_error(ThinkingSphinx::Search::StaleIdsException) { |err|
          err.ids.should == [14]
        }
      end
    end
  end
end