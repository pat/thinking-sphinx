# frozen_string_literal: true

module ThinkingSphinx::Core::Property
  def facet?
    options[:facet]
  end

  def multi?
    false
  end

  def type
    nil
  end
end
