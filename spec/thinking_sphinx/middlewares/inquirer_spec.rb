module ThinkingSphinx
  module Middlewares; end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/inquirer'

describe ThinkingSphinx::Middlewares::Inquirer do
  let(:app)            { double('app', :call => true) }
  let(:middleware)     { ThinkingSphinx::Middlewares::Inquirer.new app }
  let(:context)        { {:sphinxql => sphinx_sql} }
  let(:sphinx_sql)     { double('sphinx_sql',
    :to_sql => 'SELECT * FROM index') }
  let(:batch_inquirer) { double('batcher', :append_query => true,
    :results => [[:raw], [{'Variable_name' => 'meta', 'Value' => 'value'}]]) }
  let(:notifications)  { double('notifications') }

  before :each do
    notifications.stub(:instrument) do |notification, message, &block|
      block.call unless block.nil?
    end

    batch_class = double
    batch_class.stub(:new).and_yield(batch_inquirer).and_return(batch_inquirer)

    stub_const 'ActiveSupport::Notifications', notifications
    stub_const 'Riddle::Query', double(:meta => 'SHOW META')
    stub_const 'ThinkingSphinx::Search::BatchInquirer', batch_class
  end

  describe '#call' do
    it "passes through the SphinxQL from a Riddle::Query::Select object" do
      batch_inquirer.should_receive(:append_query).with('SELECT * FROM index')
      batch_inquirer.should_receive(:append_query).with('SHOW META')

      middleware.call context
    end

    it "sets up the raw results" do
      middleware.call context

      context[:raw].should == [:raw]
    end

    it "sets up the meta results as a hash" do
      middleware.call context

      context[:meta].should == {'meta' => 'value'}
    end

    it "uses the raw values as the initial results" do
      middleware.call context

      context[:results].should == [:raw]
    end
  end
end
