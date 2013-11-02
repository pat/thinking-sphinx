class ThinkingSphinx::Configuration::DistributedIndices
  def initialize(indices)
    @indices = indices
  end

  def reconcile
    grouped_indices.each do |reference, indices|
      append distributed_index(reference, indices)
    end
  end

  private

  attr_reader :indices

  def append(index)
    ThinkingSphinx::Configuration.instance.indices << index
  end

  def distributed_index(reference, indices)
    index = ThinkingSphinx::Distributed::Index.new reference
    index.local_indices += indices.collect &:name
    index
  end

  def grouped_indices
    indices.group_by &:reference
  end
end
