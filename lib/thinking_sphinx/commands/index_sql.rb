# frozen_string_literal: true

class ThinkingSphinx::Commands::IndexSQL < ThinkingSphinx::Commands::Base
  def call
    if indices.empty?
      ThinkingSphinx.before_index_hooks.each { |hook| hook.call }
    end

    configuration.indexing_strategy.call(indices) do |index_names|
      configuration.guarding_strategy.call(index_names) do |names|
        controller.index *names, :verbose => options[:verbose]
      end
    end
  end

  private

  def indices
    options[:indices] || []
  end

  def type
    'indexing'
  end
end
