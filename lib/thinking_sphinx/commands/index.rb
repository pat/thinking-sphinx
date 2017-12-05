# frozen_string_literal: true

class ThinkingSphinx::Commands::Index < ThinkingSphinx::Commands::Base
  def call
    controller.index :verbose => options[:verbose]
  end

  private

  def type
    'indexing'
  end
end
