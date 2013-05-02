class ThinkingSphinx::Deltas::IndexJob
  def initialize(indices)
    @indices = indices
    @indices << {:verbose => !ThinkingSphinx.suppress_delta_output?}
  end

  def perform
    ThinkingSphinx::Configuration.instance.controller.index @indices
    ThinkingSphinx::Connection.pool.clear

    true
  end

  def configuration
    ThinkingSphinx::Configuration.instance
  end
end
