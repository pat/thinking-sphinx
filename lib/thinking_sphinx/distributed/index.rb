class ThinkingSphinx::Distributed::Index <
  Riddle::Configuration::DistributedIndex

  attr_reader :reference, :options

  def initialize(reference)
    @reference = reference
    @options   = {}

    super reference.to_s.gsub('/', '_')
  end

  def delta?
    false
  end

  def distributed?
    true
  end

  def model
    @model ||= reference.to_s.camelize.constantize
  end

  def primary_key
    @primary_key ||= configuration.settings['primary_key'] || :id
  end

  private

  def configuration
    ThinkingSphinx::Configuration.instance
  end
end
