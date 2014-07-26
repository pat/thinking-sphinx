module ThinkingSphinx::SphinxQL
  mattr_accessor :weight, :group_by, :count

  def self.functions!
    self.weight   = {:select => 'weight()', :column => 'weight()'}
    self.group_by = {
      :select => 'groupby() AS sphinx_internal_group',
      :column => 'sphinx_internal_group'
    }
    self.count    = {
      :select => 'count(*) AS sphinx_internal_count',
      :column => 'sphinx_internal_count'
    }
  end

  def self.variables!
    self.weight   = {:select => '@weight',  :column => '@weight'}
    self.group_by = {:select => '@groupby', :column => '@groupby'}
    self.count    = {:select => '@count',   :column => '@count'}
  end

  self.functions!
end
