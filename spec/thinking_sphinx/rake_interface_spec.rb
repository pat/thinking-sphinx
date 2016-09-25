require 'spec_helper'

describe ThinkingSphinx::RakeInterface do
  let(:configuration) { double('configuration', :controller => controller) }
  let(:interface)     { ThinkingSphinx::RakeInterface.new }

  before :each do
    allow(ThinkingSphinx::Configuration).to receive_messages :instance => configuration
    allow(interface).to receive_messages(:puts => nil)
  end

  describe '#clear_all' do
    let(:controller) { double 'controller' }

    before :each do
      allow(configuration).to receive_messages(
        :indices_location => '/path/to/indices',
        :searchd          => double(:binlog_path => '/path/to/binlog')
      )

      allow(FileUtils).to receive_messages :rm_r => true
      allow(File).to receive_messages :exists? => true
    end

    it "removes the directory for the index files" do
      expect(FileUtils).to receive(:rm_r).with('/path/to/indices')

      interface.clear_all
    end

    it "removes the directory for the binlog files" do
      expect(FileUtils).to receive(:rm_r).with('/path/to/binlog')

      interface.clear_all
    end
  end

  describe '#clear_real_time' do
    let(:controller) { double 'controller' }
    let(:index)      {
      double(:type => 'rt', :render => true, :path => '/path/to/my/index')
    }

    before :each do
      allow(configuration).to receive_messages(
        :indices         => [double(:type => 'plain'), index],
        :searchd         => double(:binlog_path => '/path/to/binlog'),
        :preload_indices => true
      )

      allow(Dir).to receive_messages :[] => ['foo.a', 'foo.b']
      allow(FileUtils).to receive_messages :rm_r => true, :rm => true
      allow(File).to receive_messages :exists? => true
    end

    it 'finds each file for real-time indices' do
      expect(Dir).to receive(:[]).with('/path/to/my/index.*').and_return([])

      interface.clear_real_time
    end

    it "removes each file for real-time indices" do
      expect(FileUtils).to receive(:rm).with('foo.a')
      expect(FileUtils).to receive(:rm).with('foo.b')

      interface.clear_real_time
    end

    it "removes the directory for the binlog files" do
      expect(FileUtils).to receive(:rm_r).with('/path/to/binlog')

      interface.clear_real_time
    end
  end

  describe '#configure' do
    let(:controller) { double('controller') }

    before :each do
      allow(configuration).to receive_messages(
        :configuration_file => '/path/to/foo.conf',
        :render_to_file     => true
      )
    end

    it "renders the configuration to a file" do
      expect(configuration).to receive(:render_to_file)

      interface.configure
    end

    it "prints a message stating the file is being generated" do
      expect(interface).to receive(:puts).
        with('Generating configuration to /path/to/foo.conf')

      interface.configure
    end
  end

  describe '#index' do
    let(:controller) { double('controller', :index => true) }

    before :each do
      allow(ThinkingSphinx).to receive_messages :before_index_hooks => []
      allow(configuration).to receive_messages(
        :configuration_file => '/path/to/foo.conf',
        :render_to_file     => true,
        :indices_location   => '/path/to/indices'
      )

      allow(FileUtils).to receive_messages :mkdir_p => true
    end

    it "renders the configuration to a file by default" do
      expect(configuration).to receive(:render_to_file)

      interface.index
    end

    it "does not render the configuration if requested" do
      expect(configuration).not_to receive(:render_to_file)

      interface.index false
    end

    it "creates the directory for the index files" do
      expect(FileUtils).to receive(:mkdir_p).with('/path/to/indices')

      interface.index
    end

    it "calls all registered hooks" do
      called = false
      ThinkingSphinx.before_index_hooks << Proc.new { called = true }

      interface.index

      expect(called).to be_truthy
    end

    it "indexes all indices verbosely" do
      expect(controller).to receive(:index).with(:verbose => true)

      interface.index
    end

    it "does not index verbosely if requested" do
      expect(controller).to receive(:index).with(:verbose => false)

      interface.index true, false
    end
  end

  describe '#start' do
    let(:controller) { double('controller', :start => result, :pid => 101) }
    let(:result)     { double 'result', :command => 'start', :status => 1,
      :output => '' }

    before :each do
      allow(controller).to receive(:running?).and_return(false, true)
      allow(configuration).to receive_messages(
        :indices_location => 'my/index/files',
        :searchd          => double(:log => '/path/to/log')
      )

      allow(FileUtils).to receive_messages :mkdir_p => true
    end

    it "creates the index files directory" do
      expect(FileUtils).to receive(:mkdir_p).with('my/index/files')

      interface.start
    end

    it "starts the daemon" do
      expect(controller).to receive(:start)

      interface.start
    end

    it "raises an error if the daemon is already running" do
      allow(controller).to receive_messages :running? => true

      expect {
        interface.start
      }.to raise_error(ThinkingSphinx::SphinxAlreadyRunning)
    end

    it "prints a success message if the daemon has started" do
      allow(controller).to receive(:running?).and_return(false, true)

      expect(interface).to receive(:puts).
        with('Started searchd successfully (pid: 101).')

      interface.start
    end

    it "prints a failure message if the daemon does not start" do
      allow(controller).to receive(:running?).and_return(false, false)
      allow(interface).to receive(:exit)

      expect(interface).to receive(:puts) do |string|
        expect(string).to match('The Sphinx start command failed')
      end

      interface.start
    end
  end

  describe '#stop' do
    let(:controller) { double('controller', :stop => true, :pid => 101) }
    let(:result)     { double 'result', :command => 'start', :status => 1,
      :output => '' }

    before :each do
      allow(controller).to receive(:running?).and_return(true, true, false)
    end

    it "prints a message if the daemon is not already running" do
      allow(controller).to receive_messages :running? => false

      expect(interface).to receive(:puts).with('searchd is not currently running.')

      interface.stop
    end

    it "stops the daemon" do
      expect(controller).to receive(:stop)

      interface.stop
    end

    it "prints a message informing the daemon has stopped" do
      expect(interface).to receive(:puts).with('Stopped searchd daemon (pid: 101).')

      interface.stop
    end

    it "should retry stopping the daemon until it stops" do
      allow(controller).to receive(:running?).
        and_return(true, true, true, false)

      expect(controller).to receive(:stop).twice

      interface.stop
    end
  end

  describe '#status' do
    let(:controller) { double('controller') }

    it "reports when the daemon is running" do
      allow(controller).to receive_messages :running? => true

      expect(interface).to receive(:puts).
        with('The Sphinx daemon searchd is currently running.')

      interface.status
    end

    it "reports when the daemon is not running" do
      allow(controller).to receive_messages :running? => false

      expect(interface).to receive(:puts).
        with('The Sphinx daemon searchd is not currently running.')

      interface.status
    end
  end
end
