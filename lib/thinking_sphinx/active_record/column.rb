class ThinkingSphinx::ActiveRecord::Column
  def initialize(*stack)
    @stack = stack
    @name  = stack.pop
  end

  def __name
    @name
  end

  def __stack
    @stack
  end

  def string?
    __name.is_a?(String)
  end

  def to_ary
    [self]
  end

  private

  def method_missing(method, *args, &block)
    @stack << @name
    @name = method
    self
  end
end
