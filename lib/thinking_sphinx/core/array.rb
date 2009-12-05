module ThinkingSphinx
  module SearchAsArray
    def ===(object)
      object.is_a?(ThinkingSphinx::Search) || super
    end
  end

  module ArrayExtractOptions
    def extract_options!
      last.is_a?(::Hash) ? pop : {}
    end
  end
end

Array.class_eval do
  extend ThinkingSphinx::SearchAsArray
  unless instance_methods.include?("extract_options!")
    include ThinkingSphinx::ArrayExtractOptions
  end
end
