# frozen_string_literal: true

module SphinxHelpers
  def sphinx
    @sphinx ||= SphinxController.new
  end

  def index(*indices)
    sleep 0.5 if ENV['CI']

    yield if block_given?

    sphinx.index *indices
    sleep 0.25
    sleep 0.5 if ENV['CI']
  end

  def merge
    sleep 0.5 if ENV['CI']
    sleep 0.5

    sphinx.merge
    sleep 1.5
    sleep 0.5 if ENV['CI']
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

  config.after :suite do
    SphinxController.new.stop
  end
end
