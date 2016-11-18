class ThinkingSphinx::Deltas::IndexJob
  def initialize(index_name)
    @index_name = index_name
  end

  def perform
    configuration.controller.index @index_name, :verbose => !quiet_deltas?
  end

  private

  def configuration
    @configuration ||= ThinkingSphinx::Configuration.instance
  end

  def quiet_deltas?
    configuration.settings['quiet_deltas'].nil? ||
    configuration.settings['quiet_deltas']
  end
end
