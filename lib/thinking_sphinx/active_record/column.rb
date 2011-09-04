class ThinkingSphinx::ActiveRecord::Column
  def initialize(*stack)
    @stack = stack
  end

  def __name
    @stack.last
  end
end
