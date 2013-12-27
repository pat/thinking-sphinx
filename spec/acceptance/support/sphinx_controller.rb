class SphinxController
  def initialize
    config.searchd.mysql41 = 9307
  end

  def setup
    FileUtils.mkdir_p config.indices_location
    config.render_to_file && index

    ThinkingSphinx::Configuration.reset

    if ENV['SPHINX_VERSION'].try :[], /2.1.\d/
      ThinkingSphinx::SphinxQL.functions!
      ThinkingSphinx::Configuration.instance.settings['utf8'] = true
    elsif ENV['SPHINX_VERSION'].try :[], /2.0.\d/
      ThinkingSphinx::SphinxQL.variables!
      ThinkingSphinx::Configuration.instance.settings['utf8'] = false

      ThinkingSphinx::Middlewares::DEFAULT.insert_after(
        ThinkingSphinx::Middlewares::Inquirer,
        ThinkingSphinx::Middlewares::UTF8
      )
      ThinkingSphinx::Middlewares::RAW_ONLY.insert_after(
        ThinkingSphinx::Middlewares::Inquirer,
        ThinkingSphinx::Middlewares::UTF8
      )
    end

    ActiveSupport::Dependencies.loaded.each do |path|
      $LOADED_FEATURES.delete "#{path}.rb"
    end

    ActiveSupport::Dependencies.clear

    config.searchd.mysql41 = 9307
    config.settings['quiet_deltas']      = true
    config.settings['attribute_updates'] = true
    config.controller.bin_path           = ENV['SPHINX_BIN'] || ''
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
