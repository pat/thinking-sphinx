class ThinkingSphinx::Configuration < Riddle::Configuration
  attr_accessor :configuration_file, :indices_location, :version
  attr_reader :index_paths
  attr_writer :controller, :framework

  def initialize
    super

    @configuration_file = File.join framework.root, 'config',
      "#{framework.environment}.sphinx.conf"
    @index_paths        = [File.join(framework.root, 'app', 'indices')]
    @indices_location   = File.join framework.root, 'db', 'sphinx',
      framework.environment
    @version            = settings['version'] || '2.0.6'

    searchd.pid_file    = File.join framework.root, 'log',
      "#{framework.environment}.sphinx.pid"
    searchd.log         = File.join framework.root, 'log',
      "#{framework.environment}.searchd.log"
    searchd.query_log   = File.join framework.root, 'log',
      "#{framework.environment}.searchd.query.log"
    searchd.binlog_path = File.join framework.root, 'tmp', 'binlog',
      framework.environment

    searchd.address   = settings['address']
    searchd.address   = Defaults::ADDRESS unless searchd.address.present?
    searchd.mysql41   = settings['mysql41'] || settings['port'] ||
      Defaults::PORT
    searchd.workers   = 'threads'

   [indexer, searchd].each do |object|
      settings.each do |key, value|
        next unless object.class.settings.include?(key.to_sym)

        object.send("#{key}=", value)
      end
    end

    @offsets = {}
  end

  def self.instance
    @instance ||= new
  end

  def self.reset
    @instance = nil
  end

  def controller
    @controller ||= begin
      rc = Riddle::Controller.new self, configuration_file
      if settings['bin_path'].present?
        rc.bin_path = settings['bin_path'].gsub(/([^\/])$/, '\1/')
      end
      rc
    end
  end

  def framework
    @framework ||= ThinkingSphinx::Frameworks.current
  end

  def indices_for_references(*references)
    preload_indices
    indices.select { |index| references.include?(index.reference) }
  end

  def next_offset(reference)
    @offsets[reference] ||= @offsets.keys.count
  end

  def preload_indices
    return if @preloaded_indices

    index_paths.each do |path|
      Dir["#{path}/**/*.rb"].each do |file|
        ActiveSupport::Dependencies.require_or_load file
      end
    end

    @preloaded_indices = true
  end

  def render
    preload_indices

    ThinkingSphinx::Configuration::ConsistentIds.new(indices).reconcile

    super
  end

  def render_to_file
    FileUtils.mkdir_p searchd.binlog_path

    open(configuration_file, 'w') { |file| file.write render }
  end

  def settings
    @settings ||= File.exists?(settings_file) ? settings_to_hash : {}
  end

  private

  def settings_to_hash
    contents = YAML.load(ERB.new(File.read(settings_file)).result)
    contents && contents[framework.environment] || {}
  end

  def settings_file
    File.join framework.root, 'config', 'thinking_sphinx.yml'
  end
end

require 'thinking_sphinx/configuration/consistent_ids'
require 'thinking_sphinx/configuration/defaults'
