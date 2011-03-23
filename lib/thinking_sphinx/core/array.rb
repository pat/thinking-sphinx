# FIXME
module ThinkingSphinx
  class Search
  end
end

module SearchAsArray
  def ===(object)
    (ThinkingSphinx::Search === object) || super
  end
end

Array.extend SearchAsArray
