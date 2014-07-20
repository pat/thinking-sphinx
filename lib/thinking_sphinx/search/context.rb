class ThinkingSphinx::Search::Context
  attr_reader :search, :configuration

  def initialize(search, configuration = nil)
    @search        = search
    @configuration = configuration || ThinkingSphinx::Configuration.instance
    @memory        = {
      :results => [],
      :panes   => ThinkingSphinx::Configuration::Defaults::PANES.clone
    }
  end

  def [](key)
    @memory[key]
  end

  def []=(key, value)
    @memory[key] = value
  end
end
