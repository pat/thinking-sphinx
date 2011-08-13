require 'singleton'

class ThinkingSphinx::Configuration < Riddle::Configuration
  attr_accessor :configuration_file

  attr_reader :index_paths

  def initialize
    super

    @configuration_file = ''
    @index_paths        = []
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
