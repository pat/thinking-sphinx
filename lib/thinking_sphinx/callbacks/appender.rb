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
    add_core_callbacks
    add_delta_callbacks     if behaviours.include?(:deltas)
    add_real_time_callbacks if behaviours.include?(:real_time)
    add_update_callbacks    if behaviours.include?(:updates)
  end

  private

  attr_reader :model, :reference, :options, :block

  def add_core_callbacks
    model.after_destroy ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks
  end

  def add_delta_callbacks
    if path.empty?
      model.before_save  ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
      model.after_commit ThinkingSphinx::ActiveRecord::Callbacks::DeltaCallbacks
    else
      model.after_commit(
        ThinkingSphinx::ActiveRecord::Callbacks::AssociationDeltaCallbacks
          .new(path)
      )
    end
  end

  def add_real_time_callbacks
    model.after_save ThinkingSphinx::RealTime.callback_for(
      reference, path, &block
    )
  end

  def add_update_callbacks
    model.after_update ThinkingSphinx::ActiveRecord::Callbacks::UpdateCallbacks
  end

  def behaviours
    options[:behaviours] || []
  end

  def path
    options[:path] || []
  end
end
