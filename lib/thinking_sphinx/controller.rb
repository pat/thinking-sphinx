# frozen_string_literal: true

class ThinkingSphinx::Controller < Riddle::Controller
  def index(*indices)
    configuration = ThinkingSphinx::Configuration.instance
    options       = indices.extract_options!

    configuration.indexing_strategy.call(indices) do |index_names|
      configuration.guarding_strategy.call(index_names) do |names|
        super(*(names + [options]))
      end
    end
  end
end
