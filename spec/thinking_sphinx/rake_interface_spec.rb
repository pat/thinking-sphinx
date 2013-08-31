require 'spec_helper'

describe ThinkingSphinx::RakeInterface do
  let(:configuration) { double('configuration', :controller => controller) }
  let(:interface)     { ThinkingSphinx::RakeInterface.new }

  before :each do
    ThinkingSphinx::Configuration.stub :instance => configuration
    interface.stub(:puts => nil)
  end

  describe '#clear' do
    let(:controller) { double 'controller' }

    before :each do
      configuration.stub(
        :indices_location => '/path/to/indices',
        :searchd          => double(:binlog_path => '/path/to/binlog')
      )

      FileUtils.stub :rm_r => true
      File.stub :exists? => true
    end

    it "removes the directory for the index files" do
      FileUtils.should_receive(:rm_r).with('/path/to/indices')

      interface.clear
    end

    it "removes the directory for the binlog files" do
      FileUtils.should_receive(:rm_r).with('/path/to/binlog')

      interface.clear
    end
  end

  describe '#configure' do
    let(:controller) { double('controller') }

    before :each do
      configuration.stub(
        :configuration_file => '/path/to/foo.conf',
        :render_to_file     => true
      )
    end

    it "renders the configuration to a file" do
      configuration.should_receive(:render_to_file)

      interface.configure
    end

    it "prints a message stating the file is being generated" do
      interface.should_receive(:puts).
        with('Generating configuration to /path/to/foo.conf')

      interface.configure
    end
  end

  describe '#index' do
    let(:controller) { double('controller', :index => true) }

    before :each do
      ThinkingSphinx.stub :before_index_hooks => []
      configuration.stub(
        :configuration_file => '/path/to/foo.conf',
        :render_to_file     => true,
        :indices_location   => '/path/to/indices'
      )

      FileUtils.stub :mkdir_p => true
    end

    it "renders the configuration to a file by default" do
      configuration.should_receive(:render_to_file)

      interface.index
    end

    it "does not render the configuration if requested" do
      configuration.should_not_receive(:render_to_file)

      interface.index false
    end

    it "creates the directory for the index files" do
      FileUtils.should_receive(:mkdir_p).with('/path/to/indices')

      interface.index
    end

    it "calls all registered hooks" do
      called = false
      ThinkingSphinx.before_index_hooks << Proc.new { called = true }

      interface.index

      called.should be_true
    end

    it "indexes all indices verbosely" do
      controller.should_receive(:index).with(:verbose => true)

      interface.index
    end

    it "does not index verbosely if requested" do
      controller.should_receive(:index).with(:verbose => false)

      interface.index true, false
    end
  end

  describe '#start' do
    let(:controller) { double('controller', :start => true, :pid => 101) }

    before :each do
      controller.stub(:running?).and_return(false, true)
      configuration.stub :indices_location => 'my/index/files'

      FileUtils.stub :mkdir_p => true
    end

    it "creates the index files directory" do
      FileUtils.should_receive(:mkdir_p).with('my/index/files')

      interface.start
    end

    it "starts the daemon" do
      controller.should_receive(:start)

      interface.start
    end

    it "raises an error if the daemon is already running" do
      controller.stub :running? => true

      lambda {
        interface.start
      }.should raise_error(RuntimeError)
    end

    it "prints a success message if the daemon has started" do
      controller.stub(:running?).and_return(false, true)

      interface.should_receive(:puts).
        with('Started searchd successfully (pid: 101).')

      interface.start
    end

    it "prints a failure message if the daemon does not start" do
      controller.stub(:running?).and_return(false, false)

      interface.should_receive(:puts).
        with('Failed to start searchd. Check the log files for more information.')

      interface.start
    end
  end

  describe '#stop' do
    let(:controller) { double('controller', :stop => true, :pid => 101) }

    before :each do
      controller.stub :running? => true
    end

    it "prints a message if the daemon is not already running" do
      controller.stub :running? => false

      interface.should_receive(:puts).with('searchd is not currently running.')

      interface.stop
    end

    it "stops the daemon" do
      controller.should_receive(:stop)

      interface.stop
    end

    it "prints a message informing the daemon has stopped" do
      interface.should_receive(:puts).with('Stopped searchd daemon (pid: 101).')

      interface.stop
    end

    it "should retry stopping the daemon until it stops" do
      controller.should_receive(:stop).twice.and_return(false, true)

      interface.stop
    end
  end
end
