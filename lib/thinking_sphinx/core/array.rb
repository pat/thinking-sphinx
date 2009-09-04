module SearchAsArray
  def ===(object)
    object.is_a?(ThinkingSphinx::Search) || super
  end
end

Array.extend SearchAsArray
