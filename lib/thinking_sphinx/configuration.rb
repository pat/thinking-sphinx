require 'pathname'

class ThinkingSphinx::Configuration < Riddle::Configuration
  attr_accessor :configuration_file, :indices_location, :version
  attr_reader :index_paths
  attr_writer :controller

  delegate :environment, :to => :framework

  def initialize
    super

    setup
  end

  def self.instance
    @instance ||= new
  end

  def self.reset
    @instance = nil
  end

  def bin_path
    settings['bin_path']
  end

  def controller
    @controller ||= begin
      rc = ThinkingSphinx::Controller.new self, configuration_file
      rc.bin_path = bin_path.gsub(/([^\/])$/, '\1/') if bin_path.present?
      rc
    end
  end

  def framework
    @framework ||= ThinkingSphinx::Frameworks.current
  end

  def framework=(framework)
    @framework = framework
    setup
    framework
  end

  def engine_index_paths
    return [] unless defined?(Rails)

    engine_indice_paths.flatten.compact
  end

  def engine_indice_paths
    Rails::Engine.subclasses.collect(&:instance).collect do |engine|
      engine.paths.add 'app/indices' unless engine.paths['app/indices']
      engine.paths['app/indices'].existent
    end
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
      Dir["#{path}/**/*.rb"].sort.each do |file|
        ActiveSupport::Dependencies.require_or_load file
      end
    end

    ThinkingSphinx::Configuration::DistributedIndices.new(indices).reconcile

    @preloaded_indices = true
  end

  def render
    preload_indices

    ThinkingSphinx::Configuration::ConsistentIds.new(indices).reconcile
    ThinkingSphinx::Configuration::MinimumFields.new(indices).reconcile

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

  def configure_searchd
    configure_searchd_log_files

    searchd.binlog_path = tmp_path.join('binlog', environment).to_s
    searchd.address = settings['address'].presence || Defaults::ADDRESS
    searchd.mysql41 = settings['mysql41'] || settings['port'] || Defaults::PORT
    searchd.workers = 'threads'
  end

  def configure_searchd_log_files
    searchd.pid_file = log_root.join("#{environment}.sphinx.pid").to_s
    searchd.log = log_root.join("#{environment}.searchd.log").to_s
    searchd.query_log = log_root.join("#{environment}.searchd.query.log").to_s
  end

  def log_root
    framework_root.join('log').realpath
  end

  def framework_root
    Pathname.new(framework.root)
  end

  def settings_to_hash
    contents = YAML.load(ERB.new(File.read(settings_file)).result)
    contents && contents[environment] || {}
  end

  def settings_file
    framework_root.join 'config', 'thinking_sphinx.yml'
  end

  def setup
    @settings = nil
    @configuration_file = settings['configuration_file'] || framework_root.join(
      'config', "#{environment}.sphinx.conf"
    ).to_s
    @index_paths = engine_index_paths + [framework_root.join('app', 'indices').to_s]
    @indices_location = settings['indices_location'] || framework_root.join(
      'db', 'sphinx', environment
    ).to_s
    @version = settings['version'] || '2.0.6'

    configure_searchd

    apply_sphinx_settings!

    @offsets = {}
  end

  def tmp_path
    path = framework_root.join('tmp')
    File.exists?(path) ? path.realpath : path
  end

  def apply_sphinx_settings!
    [indexer, searchd].each do |object|
      settings.each do |key, value|
        next unless object.class.settings.include?(key.to_sym)

        object.send("#{key}=", value)
      end
    end
  end
end

require 'thinking_sphinx/configuration/consistent_ids'
require 'thinking_sphinx/configuration/defaults'
require 'thinking_sphinx/configuration/distributed_indices'
require 'thinking_sphinx/configuration/minimum_fields'
