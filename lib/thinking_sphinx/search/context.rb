class ThinkingSphinx::Search::Context
  attr_reader :search, :configuration

  def initialize(search, configuration = nil)
    @search        = search
    @configuration = configuration || ThinkingSphinx::Configuration.instance
    @memory        = {:results => [], :panes => []}
  end

  def [](key)
    @memory[key]
  end

  def []=(key, value)
    @memory[key] = value
  end

  def log(notification, message, &block)
    ActiveSupport::Notifications.instrument(
      "#{notification}.thinking_sphinx", notification => message, &block
    )
  end
end
