class Categorisation < ActiveRecord::Base
  belongs_to :category
  belongs_to :product

  after_save ThinkingSphinx::RealTime::Callbacks::RealTimeCallbacks.new(:product, [:product])
end
