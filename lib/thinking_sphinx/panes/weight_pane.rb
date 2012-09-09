class ThinkingSphinx::Panes::WeightPane
  def initialize(context, object, raw)
    @raw = raw
  end

  def weight
    @raw['@weight']
  end
end
