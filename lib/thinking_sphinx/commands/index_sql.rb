# frozen_string_literal: true

class ThinkingSphinx::Commands::IndexSQL < ThinkingSphinx::Commands::Base
  def call
    ThinkingSphinx.before_index_hooks.each { |hook| hook.call }

    controller.index *indices, :verbose => options[:verbose]
  end

  private

  def indices
    options[:indices] || []
  end

  def type
    'indexing'
  end
end
