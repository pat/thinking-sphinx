class ThinkingSphinx::Panes::WeightPane
  def initialize(context, object, raw)
    @raw = raw
  end

  def weight
    @raw[ThinkingSphinx::SphinxQL.weight]
  end
end
