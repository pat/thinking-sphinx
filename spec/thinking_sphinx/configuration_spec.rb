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
        should == File.join(Rails.root, 'config', 'test.sphinx.conf')
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

    it "sets the bin path from the thinking_sphinx.yml file" do
      write_configuration('bin_path' => '/foo/bar/bin/')

      config.controller.bin_path.should == '/foo/bar/bin/'
    end

    it "appends a backslash to the bin_path if appropriate" do
      write_configuration('bin_path' => '/foo/bar/bin')

      config.controller.bin_path.should == '/foo/bar/bin/'
    end
  end

  describe '#index_paths' do
    it "uses app/indices in the Rails app by default" do
      config.index_paths.should == [File.join(Rails.root, 'app', 'indices')]
    end
  end

  describe '#indices_for_references' do
    it "selects from the full index set those with matching references" do
      config.indices << double('index', :reference => :article)
      config.indices << double('index', :reference => :book)
      config.indices << double('index', :reference => :page)

      config.indices_for_references(:book, :article).length.should == 2
    end
  end

  describe '#indices_location' do
    it "stores index files in db/sphinx/ENVIRONMENT" do
      config.indices_location.
        should == File.join(Rails.root, 'db', 'sphinx', 'test')
    end
  end

  describe '#initialize' do
    it "sets the daemon pid file within log for the Rails app" do
      config.searchd.pid_file.
        should == File.join(Rails.root, 'log', 'test.sphinx.pid')
    end

    it "sets the daemon log within log for the Rails app" do
      config.searchd.log.
        should == File.join(Rails.root, 'log', 'test.searchd.log')
    end

    it "sets the query log within log for the Rails app" do
      config.searchd.query_log.
        should == File.join(Rails.root, 'log', 'test.searchd.query.log')
    end

    it "sets indexer settings if within thinking_sphinx.yml" do
      write_configuration 'mem_limit' => '128M'

      config.indexer.mem_limit.should == '128M'
    end

    it "sets searchd settings if within thinking_sphinx.yml" do
      write_configuration 'workers' => 'none'

      config.searchd.workers.should == 'none'
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

  describe '#preload_indices' do
    it "searches each index path for ruby files" do
      config.index_paths.replace ['/path/to/indices', '/path/to/other/indices']

      Dir.should_receive(:[]).with('/path/to/indices/**/*.rb').once.
        and_return([])
      Dir.should_receive(:[]).with('/path/to/other/indices/**/*.rb').once.
        and_return([])

      config.preload_indices
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

      config.preload_indices
    end

    it "does not double-load indices" do
      config.index_paths.replace ['/path/to/indices']
      Dir.stub! :[] => [
        '/path/to/indices/foo_index.rb',
        '/path/to/indices/bar_index.rb'
      ]

      ActiveSupport::Dependencies.should_receive(:require_or_load).
        with('/path/to/indices/foo_index.rb').once
      ActiveSupport::Dependencies.should_receive(:require_or_load).
        with('/path/to/indices/bar_index.rb').once

      config.preload_indices
      config.preload_indices
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

    it "does not double-load indices" do
      config.index_paths.replace ['/path/to/indices']
      Dir.stub! :[] => [
        '/path/to/indices/foo_index.rb',
        '/path/to/indices/bar_index.rb'
      ]

      ActiveSupport::Dependencies.should_receive(:require_or_load).
        with('/path/to/indices/foo_index.rb').once
      ActiveSupport::Dependencies.should_receive(:require_or_load).
        with('/path/to/indices/bar_index.rb').once

      config.preload_indices
      config.preload_indices
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

  describe '#searchd' do
    describe '#address' do
      it "defaults to 127.0.0.1" do
        config.searchd.address.should == '127.0.0.1'
      end

      it "respects the address setting" do
        write_configuration('address' => '10.11.12.13')

        config.searchd.address.should == '10.11.12.13'
      end
    end

    describe '#mysql41' do
      it "defaults to 9306" do
        config.searchd.mysql41.should == 9306
      end

      it "respects the port setting" do
        write_configuration('port' => 9313)

        config.searchd.mysql41.should == 9313
      end

      it "respects the mysql41 setting" do
        write_configuration('mysql41' => 9307)

        config.searchd.mysql41.should == 9307
      end
    end
  end

  describe '#settings' do
    context 'YAML file exists' do
      before :each do
        File.stub :exists? => true
      end

      it "reads from the YAML file" do
        File.should_receive(:read).and_return('')

        config.settings
      end

      it "uses the settings for the given environment" do
        File.stub :read => {
          'test'    => {'foo' => 'bar'},
          'staging' => {'baz' => 'qux'}
        }.to_yaml
        Rails.stub :env => 'staging'

        config.settings['baz'].should == 'qux'
      end

      it "remembers the file contents" do
        File.should_receive(:read).and_return('')

        config.settings
        config.settings
      end

      it "returns an empty hash when no settings for the environment exist" do
        File.stub :read => {'test' => {'foo' => 'bar'}}.to_yaml
        Rails.stub :env => 'staging'

        config.settings.should == {}
      end
    end

    context 'YAML file does not exist' do
      before :each do
        File.stub :exists? => false
      end

      it "does not read the file" do
        File.should_not_receive(:read)

        config.settings
      end

      it "returns an empty hash" do
        config.settings.should == {}
      end
    end
  end
end
