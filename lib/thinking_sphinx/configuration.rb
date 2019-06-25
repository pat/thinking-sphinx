# frozen_string_literal: true

require 'pathname'

class ThinkingSphinx::Configuration < Riddle::Configuration
  attr_accessor :configuration_file, :indices_location, :version, :batch_size
  attr_reader :index_paths
  attr_writer :controller, :index_set_class, :indexing_strategy,
    :guarding_strategy

  delegate :environment, :to => :framework

  @@mutex = defined?(ActiveSupport::Concurrency::LoadInterlockAwareMonitor) ?
    ActiveSupport::Concurrency::LoadInterlockAwareMonitor.new : Mutex.new

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
      rc = Riddle::Controller.new self, configuration_file
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
        Dir["#{path}/**/*.rb"].sort.each { |file| load file }
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
    unless settings['skip_directory_creation'] || searchd.binlog_path.blank?
      FileUtils.mkdir_p searchd.binlog_path
    end

    open(configuration_file, 'w') { |file| file.write render }
  end

  def settings
    @settings ||= ThinkingSphinx::Settings.call self
  end

  def setup
    @configuration_file = settings['configuration_file']
    @index_paths = engine_index_paths +
      [Pathname.new(framework.root).join('app', 'indices').to_s]
    @indices_location = settings['indices_location']
    @version = settings['version'] || '2.2.11'
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
    searchd.socket = "#{settings["socket"]}:mysql41" if socket?

    if tcp?
      searchd.address = settings['address'].presence || Defaults::ADDRESS
      searchd.mysql41 = settings['mysql41'] || settings['port'] || Defaults::PORT
    end

    searchd.mysql_version_string = '5.5.21' if RUBY_PLATFORM == 'java'
  end

  def normalise
    if settings['distributed_indices'].nil? || settings['distributed_indices']
      ThinkingSphinx::Configuration::DistributedIndices.new(indices).reconcile
    end

    ThinkingSphinx::Configuration::ConsistentIds.new(indices).reconcile
    ThinkingSphinx::Configuration::MinimumFields.new(indices).reconcile
  end

  def reset
    @settings = nil
    setup
  end

  def socket?
    settings["socket"].present?
  end

  def sphinx_sections
    sections = [indexer, searchd]
    sections.unshift common if settings['common_sphinx_configuration']
    sections
  end

  def tcp?
    settings["socket"].nil?      ||
    settings["address"].present? ||
    settings["mysql41"].present? ||
    settings["port"].present?
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
