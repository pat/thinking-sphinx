# frozen_string_literal: true

class Product < ActiveRecord::Base
  has_many :categorisations
  has_many :categories, :through => :categorisations

  after_save ThinkingSphinx::RealTime.callback_for(:product)
end
