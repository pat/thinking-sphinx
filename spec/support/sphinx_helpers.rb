module SphinxHelpers
  def index(*indices)
    yield if block_given?

    ThinkingSphinx::Configuration.instance.controller.index *indices
    sleep 0.25
  end
end

RSpec.configure do |config|
  config.include SphinxHelpers
end
