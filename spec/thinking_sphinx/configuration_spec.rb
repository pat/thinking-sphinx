# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::Configuration do
  let(:config) { ThinkingSphinx::Configuration.instance }

  after :each do
    ThinkingSphinx::Configuration.reset
  end

  describe '.instance' do
    it "returns an instance of ThinkingSphinx::Configuration" do
      expect(ThinkingSphinx::Configuration.instance).
        to be_a(ThinkingSphinx::Configuration)
    end

    it "memoizes the instance" do
      config = double('configuration')

      expect(ThinkingSphinx::Configuration).to receive(:new).once.and_return(config)

      ThinkingSphinx::Configuration.instance
      ThinkingSphinx::Configuration.instance
    end
  end

  describe '.reset' do
    after :each do
      config.framework = ThinkingSphinx::Frameworks.current
    end

    it 'does not cache settings after reset' do
      allow(File).to receive_messages :exists? => true
      allow(File).to receive_messages :read => {
        'test'       => {'foo' => 'bugs'},
        'production' => {'foo' => 'bar'}
      }.to_yaml

      ThinkingSphinx::Configuration.reset
      # Grab a new copy of the instance.
      config = ThinkingSphinx::Configuration.instance
      expect(config.settings['foo']).to eq('bugs')

      config.framework = double :environment => 'production', :root => Pathname.new(__FILE__).join('..', '..', 'internal')
      expect(config.settings['foo']).to eq('bar')
    end
  end

  describe '#configuration_file' do
    it "uses the Rails environment in the configuration file name" do
      expect(config.configuration_file).
        to eq(File.join(Rails.root, 'config', 'test.sphinx.conf'))
    end

    it "respects provided settings" do
      write_configuration 'configuration_file' => '/path/to/foo.conf'

      expect(config.configuration_file).to eq('/path/to/foo.conf')
    end
  end

  describe '#controller' do
    it "returns an instance of Riddle::Controller" do
      expect(config.controller).to be_a(Riddle::Controller)
    end

    it "memoizes the instance" do
      expect(Riddle::Controller).to receive(:new).once.
        and_return(double('controller'))

      config.controller
      config.controller
    end

    it "sets the bin path from the thinking_sphinx.yml file" do
      write_configuration('bin_path' => '/foo/bar/bin/')

      expect(config.controller.bin_path).to eq('/foo/bar/bin/')
    end

    it "appends a backslash to the bin_path if appropriate" do
      write_configuration('bin_path' => '/foo/bar/bin')

      expect(config.controller.bin_path).to eq('/foo/bar/bin/')
    end
  end

  describe '#index_paths' do
    it "uses app/indices in the Rails app by default" do
      expect(config.index_paths).to include(File.join(Rails.root, 'app', 'indices'))
    end

    it "uses app/indices in the Rails engines" do
      engine = double :engine, { :paths => { 'app/indices' =>
        double(:path, { :existent => '/engine/app/indices' } )
      } }
      engine_class = double :instance => engine

      expect(Rails::Engine).to receive(:subclasses).and_return([ engine_class ])

      expect(config.index_paths).to include('/engine/app/indices')
    end
  end

  describe '#indices_location' do
    it "stores index files in db/sphinx/ENVIRONMENT" do
      expect(config.indices_location).
        to eq(File.join(Rails.root, 'db', 'sphinx', 'test'))
    end

    it "respects provided settings" do
      write_configuration 'indices_location' => '/my/index/files'

      expect(config.indices_location).to eq('/my/index/files')
    end

    it "respects relative paths" do
      write_configuration 'indices_location' => 'my/index/files'

      expect(config.indices_location).to eq('my/index/files')
    end

    it "translates relative paths to absolute if config requests it" do
      write_configuration(
        'indices_location' => 'my/index/files',
        'absolute_paths'   => true
      )

      expect(config.indices_location).to eq(
        File.join(config.framework.root, 'my/index/files')
      )
    end

    it "respects paths that are already absolute" do
      write_configuration(
        'indices_location' => '/my/index/files',
        'absolute_paths'   => true
      )

      expect(config.indices_location).to eq('/my/index/files')
    end

    it "translates linked directories" do
      write_configuration(
        'indices_location' => 'mine/index/files',
        'absolute_paths'   => true
      )

      framework   = ThinkingSphinx::Frameworks.current
      local_path  = File.join framework.root, "mine"
      linked_path = File.join framework.root, "my"

      FileUtils.mkdir_p linked_path
      `ln -s #{linked_path} #{local_path}`

      expect(config.indices_location).to eq(
        File.join(config.framework.root, "my/index/files")
      )

      FileUtils.rm local_path
      FileUtils.rmdir linked_path
    end
  end

  describe '#initialize' do
    before :each do
      FileUtils.rm_rf Rails.root.join('log')
    end

    it "sets the daemon pid file within log for the Rails app" do
      expect(config.searchd.pid_file).
        to eq(File.join(Rails.root, 'log', 'test.sphinx.pid'))
    end

    it "sets the daemon log within log for the Rails app" do
      expect(config.searchd.log).
        to eq(File.join(Rails.root, 'log', 'test.searchd.log'))
    end

    it "sets the query log within log for the Rails app" do
      expect(config.searchd.query_log).
        to eq(File.join(Rails.root, 'log', 'test.searchd.query.log'))
    end

    it "sets indexer settings if within thinking_sphinx.yml" do
      write_configuration 'mem_limit' => '128M'

      expect(config.indexer.mem_limit).to eq('128M')
    end

    it "sets searchd settings if within thinking_sphinx.yml" do
      write_configuration 'workers' => 'none'

      expect(config.searchd.workers).to eq('none')
    end

    it 'adds settings to indexer without common section' do
      write_configuration 'lemmatizer_base' => 'foo'

      expect(config.indexer.lemmatizer_base).to eq('foo')
    end

    it 'adds settings to common section if requested' do
      write_configuration 'lemmatizer_base' => 'foo',
        'common_sphinx_configuration' => true

      expect(config.common.lemmatizer_base).to eq('foo')
    end
  end

  describe '#next_offset' do
    let(:reference) { double('reference') }

    it "starts at 0" do
      expect(config.next_offset(reference)).to eq(0)
    end

    it "increments for each new reference" do
      expect(config.next_offset(double('reference'))).to eq(0)
      expect(config.next_offset(double('reference'))).to eq(1)
      expect(config.next_offset(double('reference'))).to eq(2)
    end

    it "doesn't increment for recorded references" do
      expect(config.next_offset(reference)).to eq(0)
      expect(config.next_offset(reference)).to eq(0)
    end
  end

  describe '#preload_indices' do
    let(:distributor) { double :reconcile => true }

    before :each do
      stub_const 'ThinkingSphinx::Configuration::DistributedIndices',
        double(:new => distributor)
    end

    it "searches each index path for ruby files" do
      config.index_paths.replace ['/path/to/indices', '/path/to/other/indices']

      expect(Dir).to receive(:[]).with('/path/to/indices/**/*.rb').once.
        and_return([])
      expect(Dir).to receive(:[]).with('/path/to/other/indices/**/*.rb').once.
        and_return([])

      config.preload_indices
    end

    it "loads each file returned" do
      config.index_paths.replace ['/path/to/indices']
      allow(Dir).to receive_messages :[] => [
        '/path/to/indices/foo_index.rb',
        '/path/to/indices/bar_index.rb'
      ]

      expect(ActiveSupport::Dependencies).to receive(:require_or_load).
        with('/path/to/indices/foo_index.rb').once
      expect(ActiveSupport::Dependencies).to receive(:require_or_load).
        with('/path/to/indices/bar_index.rb').once

      config.preload_indices
    end

    it "does not double-load indices" do
      config.index_paths.replace ['/path/to/indices']
      allow(Dir).to receive_messages :[] => [
        '/path/to/indices/foo_index.rb',
        '/path/to/indices/bar_index.rb'
      ]

      expect(ActiveSupport::Dependencies).to receive(:require_or_load).
        with('/path/to/indices/foo_index.rb').once
      expect(ActiveSupport::Dependencies).to receive(:require_or_load).
        with('/path/to/indices/bar_index.rb').once

      config.preload_indices
      config.preload_indices
    end

    it 'adds distributed indices' do
      expect(distributor).to receive(:reconcile)

      config.preload_indices
    end

    it 'does not add distributed indices if disabled' do
      write_configuration('distributed_indices' => false)

      expect(distributor).not_to receive(:reconcile)

      config.preload_indices
    end
  end

  describe '#render' do
    before :each do
      allow(config.searchd).to receive_messages :render => 'searchd { }'
    end

    it "searches each index path for ruby files" do
      config.index_paths.replace ['/path/to/indices', '/path/to/other/indices']

      expect(Dir).to receive(:[]).with('/path/to/indices/**/*.rb').once.
        and_return([])
      expect(Dir).to receive(:[]).with('/path/to/other/indices/**/*.rb').once.
        and_return([])

      config.render
    end

    it "loads each file returned" do
      config.index_paths.replace ['/path/to/indices']
      allow(Dir).to receive_messages :[] => [
        '/path/to/indices/foo_index.rb',
        '/path/to/indices/bar_index.rb'
      ]

      expect(ActiveSupport::Dependencies).to receive(:require_or_load).
        with('/path/to/indices/foo_index.rb').once
      expect(ActiveSupport::Dependencies).to receive(:require_or_load).
        with('/path/to/indices/bar_index.rb').once

      config.render
    end

    it "does not double-load indices" do
      config.index_paths.replace ['/path/to/indices']
      allow(Dir).to receive_messages :[] => [
        '/path/to/indices/foo_index.rb',
        '/path/to/indices/bar_index.rb'
      ]

      expect(ActiveSupport::Dependencies).to receive(:require_or_load).
        with('/path/to/indices/foo_index.rb').once
      expect(ActiveSupport::Dependencies).to receive(:require_or_load).
        with('/path/to/indices/bar_index.rb').once

      config.preload_indices
      config.preload_indices
    end
  end

  describe '#render_to_file' do
    let(:file)   { double('file') }
    let(:output) { config.render }

    before :each do
      allow(config.searchd).to receive_messages :render => 'searchd { }'
    end

    it "writes the rendered configuration to the file" do
      config.configuration_file = '/path/to/file.config'

      expect(config).to receive(:open).with('/path/to/file.config', 'w').
        and_yield(file)
      expect(file).to receive(:write).with(output)

      config.render_to_file
    end

    it "creates a directory at the binlog_path" do
      allow(FileUtils).to receive_messages :mkdir_p => true
      allow(config).to receive_messages :searchd => double(:binlog_path => '/path/to/binlog')

      expect(FileUtils).to receive(:mkdir_p).with('/path/to/binlog')

      config.render_to_file
    end

    it "skips creating a directory when the binlog_path is blank" do
      allow(FileUtils).to receive_messages :mkdir_p => true
      allow(config).to receive_messages :searchd => double(:binlog_path => '')

      expect(FileUtils).not_to receive(:mkdir_p)

      config.render_to_file
    end
  end

  describe '#searchd' do
    describe '#address' do
      it "defaults to 127.0.0.1" do
        expect(config.searchd.address).to eq('127.0.0.1')
      end

      it "respects the address setting" do
        write_configuration('address' => '10.11.12.13')

        expect(config.searchd.address).to eq('10.11.12.13')
      end
    end

    describe '#log' do
      it "defaults to an environment-specific file" do
        expect(config.searchd.log).to eq(
          File.join(config.framework.root, "log/test.searchd.log")
        )
      end

      it "translates linked directories" do
        framework   = ThinkingSphinx::Frameworks.current
        log_path    = File.join framework.root, "log"
        linked_path = File.join framework.root, "logging"
        log_exists  = File.exist? log_path

        FileUtils.mv log_path, "#{log_path}-tmp" if log_exists
        FileUtils.mkdir_p linked_path
        `ln -s #{linked_path} #{log_path}`

        expect(config.searchd.log).to eq(
          File.join(config.framework.root, "logging/test.searchd.log")
        )

        FileUtils.rm log_path
        FileUtils.rmdir linked_path
        FileUtils.mv "#{log_path}-tmp", log_path if log_exists
      end unless RUBY_PLATFORM == "java"
    end

    describe '#mysql41' do
      it "defaults to 9306" do
        expect(config.searchd.mysql41).to eq(9306)
      end

      it "respects the port setting" do
        write_configuration('port' => 9313)

        expect(config.searchd.mysql41).to eq(9313)
      end

      it "respects the mysql41 setting" do
        write_configuration('mysql41' => 9307)

        expect(config.searchd.mysql41).to eq(9307)
      end
    end

    describe "#socket" do
      it "does not set anything by default" do
        expect(config.searchd.socket).to be_nil
      end

      it "ignores unspecified address and port when socket is set" do
        write_configuration("socket" => "/my/socket")

        expect(config.searchd.socket).to eq("/my/socket:mysql41")
        expect(config.searchd.address).to be_nil
        expect(config.searchd.mysql41).to be_nil
      end

      it "allows address and socket settings" do
        write_configuration("socket" => "/my/socket", "address" => "1.1.1.1")

        expect(config.searchd.socket).to eq("/my/socket:mysql41")
        expect(config.searchd.address).to eq("1.1.1.1")
        expect(config.searchd.mysql41).to eq(9306)
      end

      it "allows mysql41 and socket settings" do
        write_configuration("socket" => "/my/socket", "mysql41" => 9307)

        expect(config.searchd.socket).to eq("/my/socket:mysql41")
        expect(config.searchd.address).to eq("127.0.0.1")
        expect(config.searchd.mysql41).to eq(9307)
      end

      it "allows port and socket settings" do
        write_configuration("socket" => "/my/socket", "port" => 9307)

        expect(config.searchd.socket).to eq("/my/socket:mysql41")
        expect(config.searchd.address).to eq("127.0.0.1")
        expect(config.searchd.mysql41).to eq(9307)
      end

      it "allows address, mysql41 and socket settings" do
        write_configuration(
          "socket"  => "/my/socket",
          "address" => "1.2.3.4",
          "mysql41" => 9307
        )

        expect(config.searchd.socket).to eq("/my/socket:mysql41")
        expect(config.searchd.address).to eq("1.2.3.4")
        expect(config.searchd.mysql41).to eq(9307)
      end
    end
  end

  describe '#settings' do
    context 'YAML file exists' do
      before :each do
        allow(File).to receive_messages :exists? => true
      end

      it "reads from the YAML file" do
        expect(File).to receive(:read).and_return('')

        config.settings
      end

      it "uses the settings for the given environment" do
        allow(File).to receive_messages :read => {
          'test'    => {'foo' => 'bar'},
          'staging' => {'baz' => 'qux'}
        }.to_yaml
        allow(Rails).to receive_messages :env => 'staging'

        expect(config.settings['baz']).to eq('qux')
      end

      it "remembers the file contents" do
        expect(File).to receive(:read).and_return('')

        config.settings
        config.settings
      end

      it "returns the default hash when no settings for the environment exist" do
        allow(File).to receive_messages :read => {'test' => {'foo' => 'bar'}}.to_yaml
        allow(Rails).to receive_messages :env => 'staging'

        expect(config.settings.class).to eq(Hash)
      end
    end

    context 'YAML file does not exist' do
      before :each do
        allow(File).to receive_messages :exists? => false
      end

      it "does not read the file" do
        expect(File).not_to receive(:read)

        config.settings
      end

      it "returns a hash" do
        expect(config.settings.class).to eq(Hash)
      end
    end
  end

  describe '#version' do
    it "defaults to 2.2.11" do
      expect(config.version).to eq('2.2.11')
    end

    it "respects supplied YAML versions" do
      write_configuration 'version' => '2.0.4'

      expect(config.version).to eq('2.0.4')
    end
  end
end
