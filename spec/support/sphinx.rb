class Sphinx
  def initialize
    config.searchd.mysql41 = 9307
  end

  def setup
    config.render_to_file && index
  end

  def start
    config.controller.start
  end

  def stop
    config.controller.stop
  end

  def index
    FileUtils.mkdir_p config.indices_location
    config.controller.index
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end
end

RSpec.configure do |config|
  sphinx = Sphinx.new

  config.before :all do |group|
    sphinx.setup && sphinx.start if group.class.metadata[:live]
  end

  config.after :all do |group|
    sphinx.stop if group.class.metadata[:live]
  end
end
