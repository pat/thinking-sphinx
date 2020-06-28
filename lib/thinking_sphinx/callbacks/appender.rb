# frozen_string_literal: true

class ThinkingSphinx::Callbacks::Appender
  def self.call(model, reference, options, &block)
    new(model, reference, options, &block).call
  end

  def initialize(model, reference, options, &block)
    @model = model
    @reference = reference
    @options = options
    @block = block
  end

  def call
    model.after_destroy ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks

    if behaviours.include?(:deltas)
      model.before_save  ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
      model.after_commit ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
    end

    if behaviours.include?(:real_time)
      model.after_save ThinkingSphinx::RealTime.callback_for(
        reference, path, &block
      )
    end

    if behaviours.include?(:updates)
      model.after_update(
        ThinkingSphinx::ActiveRecord::Callbacks::UpdateCallbacks
      )
    end
  end

  private

  attr_reader :model, :reference, :options, :block

  def behaviours
    options[:behaviours] || []
  end

  def path
    options[:path] || []
  end
end
