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
end
