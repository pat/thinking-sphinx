class ThinkingSphinx::Configuration::DuplicateNames
  def initialize(indices)
    @indices = indices
  end

  def reconcile
    indices.each do |index|
      return if index.distributed?

      counts_for(index).each do |name, count|
        next if count <= 1

        raise ThinkingSphinx::DuplicateNameError,
          "Duplicate field/attribute name '#{name}' in index '#{index.name}'"
      end
    end
  end

  private

  attr_reader :indices

  def counts_for(index)
    names_for(index).inject({}) do |hash, name|
      hash[name] ||= 0
      hash[name] += 1
      hash
    end
  end

  def names_for(index)
    index.fields.collect(&:name) + index.attributes.collect(&:name)
  end
end
