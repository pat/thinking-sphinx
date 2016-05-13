class ThinkingSphinx::IndexingStrategies::AllAtOnce
  def self.call(indices = [], &block)
    indices << '--all' if indices.empty?

    block.call indices
  end
end
