module ThinkingSphinx::WithOutput
  def initialize(configuration, options = {}, stream = STDOUT)
    @configuration = configuration
    @options       = options
    @stream        = stream
  end

  private

  attr_reader :configuration, :options, :stream
end
