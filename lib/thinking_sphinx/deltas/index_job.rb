# frozen_string_literal: true

class ThinkingSphinx::Deltas::IndexJob
  def initialize(index_name)
    @index_name = index_name
  end

  def perform
    ThinkingSphinx::Commander.call(
      :index_sql, configuration,
      :indices => [index_name],
      :verbose => !quiet_deltas?
    )
  end

  private

  attr_reader :index_name

  def configuration
    @configuration ||= ThinkingSphinx::Configuration.instance
  end

  def quiet_deltas?
    configuration.settings['quiet_deltas'].nil? ||
    configuration.settings['quiet_deltas']
  end
end
