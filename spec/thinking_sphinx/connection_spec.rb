require 'spec_helper'

describe ThinkingSphinx::Connection do
  describe '#client' do
    let(:connection) { ThinkingSphinx::Connection.new }

    before :each do
      @config = ThinkingSphinx::Configuration.instance
      @config.address     = 'domain.url'
      @config.port        = 3333
      @config.configuration.searchd.max_matches = 100
      @config.timeout = 1

      pending
    end

    it "should return an instance of Riddle::Client" do
      connection.client.should be_a(Riddle::Client)
    end

    it "should use the configuration address" do
      connection.client.server.should == 'domain.url'
    end

    it "should use the configuration port" do
      connection.client.port.should == 3333
    end

    it "should use the configuration max matches" do
      connection.client.max_matches.should == 100
    end

    it "should use the configuration timeout" do
      connection.client.timeout.should == 1
    end

    describe 'when shuffle is enabled' do
      let(:client) { double('client', :max_matches= => nil, :timeout= => nil,
        :open => true) }

      before :each do
        @config.shuffle = true
      end

      it "should shuffle client servers" do
        @config.address = ['1.1.1.1', '2.2.2.2']
        @config.address.stub!(:shuffle => ['2.2.2.2', '1.1.1.1'])

        Riddle::Client.should_receive(:new) do |addresses, port, key|
          addresses.should == ['2.2.2.2', '1.1.1.1']
          client
        end
        connection.client
      end
    end

    describe 'when shuffle is disabled' do
      let(:client) { double('client', :max_matches= => nil, :timeout= => nil,
        :open => true) }

      before :each do
        @config.shuffle = false
      end

      it "should not shuffle client servers" do
        @config.address = ['1.1.1.1', '2.2.2.2.', '3.3.3.3', '4.4.4.4', '5.5.5.5']

        @config.address.should_not_receive(:shuffle)
        Riddle::Client.should_receive(:new) do |addresses, port, key|
          addresses.should == ['1.1.1.1', '2.2.2.2.', '3.3.3.3', '4.4.4.4', '5.5.5.5']
          client
        end
        connection.client
      end
    end
  end

  describe '#open' do
    # open is called on initialise
    let(:client) { double :open => true }

    before :each do
      Riddle::Client.stub :new => client
    end

    it "opens the client" do
      client.should_receive(:open)

      ThinkingSphinx::Connection.new
    end

    it "does nothing if persistence is disabled" do
      ThinkingSphinx.stub :persistence_enabled? => false

      client.should_not_receive(:open)

      ThinkingSphinx::Connection.new
    end
  end

  describe '#close' do
    let(:connection) { ThinkingSphinx::Connection.new }
    let(:client)     { double :open => true }

    before :each do
      Riddle::Client.stub :new => client
    end

    it "closes the client" do
      client.should_receive(:close)

      connection.close
    end

    it "does nothing if persistence is disabled" do
      ThinkingSphinx.stub :persistence_enabled? => false

      client.should_not_receive(:close)

      connection.close
    end
  end
end
