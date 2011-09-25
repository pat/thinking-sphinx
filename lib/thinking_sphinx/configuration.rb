class ThinkingSphinx::Configuration < Riddle::Configuration
  attr_accessor :configuration_file, :indices_location

  attr_reader :index_paths

  def initialize
    super

    @configuration_file = Rails.root.join('config', "#{Rails.env}.sphinx.conf")
    @index_paths        = [Rails.root.join('app', 'indices')]
    @indices_location   = Rails.root.join('db', 'sphinx', Rails.env)

    searchd.pid_file  = Rails.root.join('log', "#{Rails.env}.sphinx.pid")
    searchd.log       = Rails.root.join('log', "#{Rails.env}.searchd.log")
    searchd.query_log = Rails.root.join('log', "#{Rails.env}.searchd.query.log")

    @offsets = {}
  end

  def self.instance
    @instance ||= new
  end

  def self.reset
    @instance = nil
  end

  def controller
    @controller ||= Riddle::Controller.new(self, configuration_file).tap do |rc|
      if settings['bin_path'].present?
        rc.bin_path = settings['bin_path'].gsub(/([^\/])$/, '\1/')
      end
    end
  end

  def indices_for_reference(reference)
    indices.select { |index| index.reference == reference }
  end

  def next_offset(reference)
    @offsets[reference] ||= @offsets.keys.count
  end

  def render
    index_paths.each do |path|
      Dir["#{path}/**/*.rb"].each do |file|
        ActiveSupport::Dependencies.require_or_load file
      end
    end

    super
  end

  def render_to_file
    open(configuration_file, 'w') { |file| file.write render }
  end

  private

  def settings
    @settings ||= if File.exists?(settings_file)
      YAML.load(ERB.new(File.read(settings_file)).result)[Rails.env]
    else
      {}
    end
  end

  def settings_file
    Rails.root.join 'config', 'sphinx.yml'
  end
end
