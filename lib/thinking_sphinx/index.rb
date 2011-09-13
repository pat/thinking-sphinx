class ThinkingSphinx::Index
  def self.define(reference, options = {}, &block)
    ThinkingSphinx::ActiveRecord::Index.new(reference).tap do |index|
      index.definition_block = block
      ThinkingSphinx::Configuration.instance.indices << index
    end
  end
end
