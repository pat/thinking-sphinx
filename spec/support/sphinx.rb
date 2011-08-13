class Sphinx
  def initialize
    config.configuration_file  = "#{root}/tmp/sphinx.conf"
    config.index_paths        << "#{root}/spec/acceptance/indices"
    config.searchd.mysql41     = 9307
    config.searchd.pid_file    = "#{root}/tmp/searchd.pid"
  end

  def setup
    FileUtils.mkdir_p "#{root}/tmp"

    config.render_to_file
  end

  def start
    config.controller.start
  end

  def stop
    config.controller.stop
  end

  def index
    config.controller.index
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end

  def root
    File.expand_path File.join(File.dirname(__FILE__), '..', '..')
  end
end
