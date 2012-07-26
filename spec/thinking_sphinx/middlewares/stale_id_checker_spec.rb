module ThinkingSphinx
  module Middlewares; end
  class  Search; end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/stale_id_checker'
require 'thinking_sphinx/search/stale_ids_exception'

describe ThinkingSphinx::Middlewares::StaleIdChecker do
  let(:app)        { double('app') }
  let(:middleware) { ThinkingSphinx::Middlewares::StaleIdChecker.new app }
  let(:context)    { {:raw => [], :results => []} }
  let(:model)      { double('model') }

  def raw_result(id, model_name)
    {'sphinx_internal_id' => id, 'sphinx_internal_class_attr' => model_name}
  end

  describe '#call' do
    it 'passes the call on if there are no nil results' do
      context[:raw] << raw_result(24, 'Article')
      context[:raw] << raw_result(42, 'Article')

      context[:results] << double('instance', :id => 24)
      context[:results] << double('instance', :id => 42)

      app.should_receive(:call)

      middleware.call context
    end

    it "raises a stale id exception if ActiveRecord doesn't return ids" do
      context[:raw] << raw_result(24, 'Article')
      context[:raw] << raw_result(42, 'Article')

      context[:results] << double('instance', :id => 24)
      context[:results] << nil

      lambda {
        middleware.call context
      }.should raise_error(ThinkingSphinx::Search::StaleIdsException) { |err|
        err.ids.should == [42]
      }
    end
  end
end
