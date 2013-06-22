class Categorisation < ActiveRecord::Base
  belongs_to :category
  belongs_to :product

  after_save ThinkingSphinx::RealTime.callback_for(:product, [:product])
end
