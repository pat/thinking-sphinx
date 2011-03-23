module SearchAsArray
  def ===(object)
    (ThinkingSphinx::Search === object) || super
  end
end

Array.extend SearchAsArray
