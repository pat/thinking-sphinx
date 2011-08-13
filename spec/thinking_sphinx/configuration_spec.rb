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
