# frozen_string_literal: true

class ThinkingSphinx::Guard::None
  def self.call(names, &block)
    block.call names
  end
end
