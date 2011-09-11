require 'spec_helper'

describe ThinkingSphinx::Configuration do
  let(:config) { ThinkingSphinx::Configuration.instance }

  after :each do
    ThinkingSphinx::Configuration.reset
  end

  describe '.instance' do
    it "returns an instance of ThinkingSphinx::Configuration" do
      ThinkingSphinx::Configuration.instance.
        should be_a(ThinkingSphinx::Configuration)
    end

    it "memoizes the instance" do
      config = double('configuration')

      ThinkingSphinx::Configuration.should_receive(:new).once.and_return(config)

      ThinkingSphinx::Configuration.instance
      ThinkingSphinx::Configuration.instance
    end
  end

  describe '#configuration_file' do
    it "uses the Rails environment in the configuration file name" do
      config.configuration_file.
        should == Rails.root.join('config', 'test.sphinx.conf')
    end
  end

  describe '#controller' do
    it "returns an instance of Riddle::Controller" do
      config.controller.should be_a(Riddle::Controller)
    end

    it "memoizes the instance" do
      Riddle::Controller.should_receive(:new).once.
        and_return(double('controller'))

      config.controller
      config.controller
    end
  end

  describe '#index_paths' do
    it "uses app/indices in the Rails app by default" do
      config.index_paths.should == [Rails.root.join('app', 'indices')]
    end
  end

  describe '#indices_for_reference' do
    it "selects from the full index set those with matching references"
  end

  describe '#indices_location' do
    it "stores index files in db/sphinx/ENVIRONMENT" do
      config.indices_location.should == Rails.root.join('db', 'sphinx', 'test')
    end
  end

  describe '#initialize' do
    it "sets the daemon pid file within log for the Rails app" do
      config.searchd.pid_file.
        should == Rails.root.join('log', 'test.sphinx.pid')
    end

    it "sets the daemon log within log for the Rails app" do
      config.searchd.log.should == Rails.root.join('log', 'test.searchd.log')
    end

    it "sets the query log within log for the Rails app" do
      config.searchd.query_log.
        should == Rails.root.join('log', 'test.searchd.query.log')
    end
  end

  describe '#next_offset' do
    let(:reference) { double('reference') }

    it "starts at 0" do
      config.next_offset(reference).should == 0
    end

    it "increments for each new reference" do
      config.next_offset(double('reference')).should == 0
      config.next_offset(double('reference')).should == 1
      config.next_offset(double('reference')).should == 2
    end

    it "doesn't increment for recorded references" do
      config.next_offset(reference).should == 0
      config.next_offset(reference).should == 0
    end
  end

  describe '#render' do
    before :each do
      config.searchd.stub! :render => 'searchd { }'
    end

    it "searches each index path for ruby files" do
      config.index_paths.replace ['/path/to/indices', '/path/to/other/indices']

      Dir.should_receive(:[]).with('/path/to/indices/**/*.rb').once.
        and_return([])
      Dir.should_receive(:[]).with('/path/to/other/indices/**/*.rb').once.
        and_return([])

      config.render
    end

    it "loads each file returned" do
      config.index_paths.replace ['/path/to/indices']
      Dir.stub! :[] => [
        '/path/to/indices/foo_index.rb',
        '/path/to/indices/bar_index.rb'
      ]

      ActiveSupport::Dependencies.should_receive(:require_or_load).
        with('/path/to/indices/foo_index.rb').once
      ActiveSupport::Dependencies.should_receive(:require_or_load).
        with('/path/to/indices/bar_index.rb').once

      config.render
    end
  end

  describe '#render_to_file' do
    let(:file)   { double('file') }
    let(:output) { config.render }

    before :each do
      config.searchd.stub! :render => 'searchd { }'
    end

    it "writes the rendered configuration to the file" do
      config.configuration_file = '/path/to/file.config'

      config.should_receive(:open).with('/path/to/file.config', 'w').
        and_yield(file)
      file.should_receive(:write).with(output)

      config.render_to_file
    end
  end
end
