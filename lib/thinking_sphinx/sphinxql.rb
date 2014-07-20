module ThinkingSphinx::SphinxQL
  mattr_accessor :weight, :group_by, :count

  def self.functions!
    self.weight   = 'weight()'
    self.group_by = 'groupby()'
    self.count    = 'count(*)'
  end

  def self.variables!
    self.weight   = '@weight'
    self.group_by = '@groupby'
    self.count    = '@count'
  end

  self.functions!
end
