module SearchAsArray
  def ===(object)
    (ThinkingSphinx::Search === object) || super
    # object.is_a?(ThinkingSphinx::Search) || super
  end
end

Array.extend SearchAsArray
