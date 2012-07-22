module ThinkingSphinx
  module Middlewares; end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/inquirer'

describe ThinkingSphinx::Middlewares::Inquirer do
  let(:app)           { double('app', :call => true) }
  let(:middleware)    { ThinkingSphinx::Middlewares::Inquirer.new app }
  let(:context)       { {:sphinxql => sphinx_sql} }
  let(:sphinx_sql)    { double('sphinx_sql',
    :to_sql => 'SELECT * FROM index') }
  let(:connection)    { double('connection') }
  let(:configuration) { double('configuration', :connection => connection) }
  let(:notifications) { double('notifications') }

  before :each do
    notifications.stub(:instrument) do |notification, message, &block|
      block.call unless block.nil?
    end
    stub_const 'ActiveSupport::Notifications', notifications
    stub_const 'Riddle::Query', double(:meta => 'SHOW META')

    context.stub :configuration => configuration
    connection.stub(:query).and_return([:raw], [
      {'Variable_name' => 'meta', 'Value' => 'value'}])
  end

  describe '#call' do
    it "populates the data and meta sets from Sphinx" do
      connection.unstub :query
      connection.should_receive(:query).twice.and_return([], [])

      middleware.call context
    end

    it "passes through the SphinxQL from a Riddle::Query::Select object" do
      connection.unstub :query
      connection.should_receive(:query).with('SELECT * FROM index').once.
        and_return([])
      connection.should_receive(:query).with('SHOW META').once.and_return([])

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
