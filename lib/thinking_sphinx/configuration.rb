class ThinkingSphinx::Configuration < Riddle::Configuration
  attr_accessor :configuration_file, :indices_location

  attr_reader :index_paths

  def initialize
    super

    @configuration_file = Rails.root.join('config', "#{Rails.env}.sphinx.conf")
    @index_paths        = [Rails.root.join('app', 'indices')]
    @indices_location   = Rails.root.join('db', 'sphinx', Rails.env)

    searchd.pid_file    = Rails.root.join('log', "#{Rails.env}.sphinx.pid")

    @offsets = {}
  end

  def self.instance
    @instance ||= new
  end

  def self.reset
    @instance = nil
  end

  def controller
    @controller ||= Riddle::Controller.new self, configuration_file
  end

  def indices_for_reference(reference)
    indexes.select { |index| index.reference == reference }
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
end
