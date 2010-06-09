module ThinkingSphinx
  class Join
    attr_accessor :source, :column, :associations
    
    def initialize(source, column)
      @source = source
      @column = column
      
      @associations = association_stack(column.__path.clone).each { |assoc|
        assoc.join_to(source.base)
      }
      
      source.joins << self
    end
    
    private
    
    # Gets a stack of associations for a specific path.
    # 
    def association_stack(path, parent = nil)
      assocs = []
      
      if parent.nil?
        assocs = @source.association(path.shift)
      else
        assocs = parent.children(path.shift)
      end
      
      until path.empty?
        point  = path.shift
        assocs = assocs.collect { |assoc| assoc.children(point) }.flatten
      end
      
      assocs
    end
  end
end
