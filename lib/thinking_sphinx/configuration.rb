class ThinkingSphinx::Configuration < Riddle::Configuration
  attr_accessor :configuration_file, :indices_location

  attr_reader :index_paths

  def initialize
    super

    @configuration_file = Rails.root.join 'config', "#{Rails.env}.sphinx.conf"
    @index_paths        = [Rails.root.join('app', 'indices')]
    @indices_location   = Rails.root.join 'db', 'sphinx', Rails.env

    searchd.pid_file  = Rails.root.join 'log', "#{Rails.env}.sphinx.pid"
    searchd.log       = Rails.root.join 'log', "#{Rails.env}.searchd.log"
    searchd.query_log = Rails.root.join 'log', "#{Rails.env}.searchd.query.log"
    searchd.binlog_path = Rails.root.join 'tmp', 'binlog', Rails.env

    searchd.address   = settings['address']
    searchd.address   = Defaults::ADDRESS unless searchd.address.present?
    searchd.mysql41   = settings['mysql41'] || settings['port'] ||
      Defaults::PORT
    # searchd.workers   = 'threads'

    @offsets = {}
  end

  def self.instance
    @instance ||= new
  end

  def self.reset
    @instance = nil
  end

  def connection
    # If you use localhost, MySQL insists on a socket connection, but Sphinx
    # requires a TCP connection. Using 127.0.0.1 fixes that.
    address = searchd.address || '127.0.0.1'
    address = '127.0.0.1' if address == 'localhost'

    Mysql2::Client.new({
      :host  => address,
      :port  => searchd.mysql41,
      :flags => Mysql2::Client::MULTI_STATEMENTS
    }.merge(settings['connection_options'] || {}))
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
    contents && contents[Rails.env] || {}
  end

  def settings_file
    Rails.root.join 'config', 'thinking_sphinx.yml'
  end
end

require 'thinking_sphinx/configuration/consistent_ids'
require 'thinking_sphinx/configuration/defaults'
