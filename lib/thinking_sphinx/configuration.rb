# frozen_string_literal: true

require 'pathname'

class ThinkingSphinx::Configuration < Riddle::Configuration
  attr_accessor :configuration_file, :indices_location, :version, :batch_size
  attr_reader :index_paths
  attr_writer :controller, :index_set_class, :indexing_strategy,
    :guarding_strategy

  delegate :environment, :to => :framework

  @@mutex = Mutex.new

  def initialize
    super

    reset
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
    reset
    framework
  end

  def engine_index_paths
    return [] unless defined?(Rails)

    engine_indice_paths.flatten.compact.sort
  end

  def engine_indice_paths
    Rails::Engine.subclasses.collect(&:instance).collect do |engine|
      engine.paths.add 'app/indices' unless engine.paths['app/indices']
      engine.paths['app/indices'].existent
    end
  end

  def guarding_strategy
    @guarding_strategy ||= ThinkingSphinx::Guard::Files
  end

  def index_set_class
    @index_set_class ||= ThinkingSphinx::IndexSet
  end

  def indexing_strategy
    @indexing_strategy ||= ThinkingSphinx::IndexingStrategies::AllAtOnce
  end

  def indices_for_references(*references)
    index_set_class.new(:references => references).to_a
  end

  def next_offset(reference)
    @offsets[reference] ||= @offsets.keys.count
  end

  def preload_indices
    @@mutex.synchronize do
      return if @preloaded_indices

      index_paths.each do |path|
        Dir["#{path}/**/*.rb"].sort.each do |file|
          ActiveSupport::Dependencies.require_or_load file
        end
      end

      normalise
      verify

      @preloaded_indices = true
    end
  end

  def render
    preload_indices

    super
  end

  def render_to_file
    FileUtils.mkdir_p searchd.binlog_path unless searchd.binlog_path.blank?

    open(configuration_file, 'w') { |file| file.write render }
  end

  def settings
    @settings ||= File.exists?(settings_file) ? settings_to_hash : {}
  end

  def setup
    @configuration_file = settings['configuration_file'] || framework_root.join(
      'config', "#{environment}.sphinx.conf"
    ).to_s
    @index_paths = engine_index_paths + [framework_root.join('app', 'indices').to_s]
    @indices_location = settings['indices_location'] || framework_root.join(
      'db', 'sphinx', environment
    ).to_s
    @version = settings['version'] || '2.1.4'
    @batch_size = settings['batch_size'] || 1000

    if settings['common_sphinx_configuration']
      common.common_sphinx_configuration  = true
      indexer.common_sphinx_configuration = true
    end

    configure_searchd

    apply_sphinx_settings!

    @offsets = {}
  end

  private

  def apply_sphinx_settings!
    sphinx_sections.each do |object|
      settings.each do |key, value|
        next unless object.class.settings.include?(key.to_sym)

        object.send("#{key}=", value)
      end
    end
  end

  def configure_searchd
    configure_searchd_log_files

    searchd.binlog_path = tmp_path.join('binlog', environment).to_s
    searchd.address = settings['address'].presence || Defaults::ADDRESS
    searchd.mysql41 = settings['mysql41'] || settings['port'] || Defaults::PORT
    searchd.workers = 'threads'
    searchd.mysql_version_string = '5.5.21' if RUBY_PLATFORM == 'java'
  end

  def configure_searchd_log_files
    searchd.pid_file = log_root.join("#{environment}.sphinx.pid").to_s
    searchd.log = log_root.join("#{environment}.searchd.log").to_s
    searchd.query_log = log_root.join("#{environment}.searchd.query.log").to_s
  end

  def framework_root
    Pathname.new(framework.root)
  end

  def log_root
    real_path 'log'
  end

  def normalise
    if settings['distributed_indices'].nil? || settings['distributed_indices']
      ThinkingSphinx::Configuration::DistributedIndices.new(indices).reconcile
    end

    ThinkingSphinx::Configuration::ConsistentIds.new(indices).reconcile
    ThinkingSphinx::Configuration::MinimumFields.new(indices).reconcile
  end

  def real_path(*arguments)
    path = framework_root.join(*arguments)
    path.exist? ? path.realpath : path
  end

  def reset
    @settings = nil
    setup
  end

  def settings_file
    framework_root.join 'config', 'thinking_sphinx.yml'
  end

  def settings_to_hash
    input    = File.read settings_file
    input    = ERB.new(input).result if defined?(ERB)

    contents = YAML.load input
    contents && contents[environment] || {}
  end

  def sphinx_sections
    sections = [indexer, searchd]
    sections.unshift common if settings['common_sphinx_configuration']
    sections
  end

  def tmp_path
    real_path 'tmp'
  end

  def verify
    ThinkingSphinx::Configuration::DuplicateNames.new(indices).reconcile
  end
end

require 'thinking_sphinx/configuration/consistent_ids'
require 'thinking_sphinx/configuration/defaults'
require 'thinking_sphinx/configuration/distributed_indices'
require 'thinking_sphinx/configuration/duplicate_names'
require 'thinking_sphinx/configuration/minimum_fields'
