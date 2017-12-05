# frozen_string_literal: true

class ThinkingSphinx::IndexingStrategies::OneAtATime
  def self.call(indices = [], &block)
    if indices.empty?
      configuration = ThinkingSphinx::Configuration.instance
      configuration.preload_indices

      indices = configuration.indices.select { |index|
        !(index.distributed? || index.type == 'rt')
      }.collect &:name
    end

    indices.each { |name| block.call [name] }
  end
end
