# frozen_string_literal: true

class ThinkingSphinx::Commands::IndexSQL < ThinkingSphinx::Commands::Base
  def call
    ThinkingSphinx.before_index_hooks.each { |hook| hook.call }

    controller.index :verbose => options[:verbose]
  end

  private

  def type
    'indexing'
  end
end
