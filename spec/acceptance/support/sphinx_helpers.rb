module SphinxHelpers
  def sphinx
    @sphinx ||= SphinxController.new
  end

  def index(*indices)
    yield if block_given?

    sphinx.index *indices
    sleep 0.25
    sleep 0.25 if ENV['TRAVIS']
  end
end

RSpec.configure do |config|
  config.include SphinxHelpers

  config.before :all do |group|
    FileUtils.rm_rf ThinkingSphinx::Configuration.instance.indices_location
    FileUtils.rm_rf ThinkingSphinx::Configuration.instance.searchd.binlog_path

    sphinx.setup && sphinx.start if group.class.metadata[:live]
  end

  config.after :all do |group|
    sphinx.stop if group.class.metadata[:live]
  end
end
