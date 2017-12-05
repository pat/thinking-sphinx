# frozen_string_literal: true

class SphinxController
  def initialize
    config.searchd.mysql41 = 9307
  end

  def setup
    FileUtils.mkdir_p config.indices_location
    config.controller.bin_path = ENV['SPHINX_BIN'] || ''
    config.render_to_file && index

    ThinkingSphinx::Configuration.reset

    ActiveSupport::Dependencies.loaded.each do |path|
      $LOADED_FEATURES.delete "#{path}.rb"
    end

    ActiveSupport::Dependencies.clear

    if ENV['SPHINX_VERSION'].try :[], /2.0.\d/
      ThinkingSphinx::Configuration.instance.settings['utf8'] = false
    end

    config.searchd.mysql41 = 9307
    config.settings['quiet_deltas']      = true
    config.settings['attribute_updates'] = true
    config.controller.bin_path           = ENV['SPHINX_BIN'] || ''
  end

  def start
    config.controller.start
  end

  def stop
    while config.controller.running? do
      config.controller.stop
      sleep(0.1)
    end
  end

  def index(*indices)
    config.controller.index *indices
  end

  private

  def config
    ThinkingSphinx::Configuration.instance
  end
end
