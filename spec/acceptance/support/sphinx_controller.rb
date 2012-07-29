class SphinxController
  def initialize
    config.searchd.mysql41 = 9307
  end

  def setup
    FileUtils.mkdir_p config.indices_location
    config.render_to_file && index

    ThinkingSphinx::Configuration.reset
    ActiveSupport::Dependencies.clear

    config.index_paths.each do |path|
      Dir["#{path}/**/*.rb"].each { |file| $LOADED_FEATURES.delete file }
    end

    config.searchd.mysql41 = 9307
  end

  def start
    config.controller.start
  end

  def stop
    config.controller.stop
  end

  def index(*indices)
    config.controller.index *indices
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end
end
