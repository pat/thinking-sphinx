# frozen_string_literal: true

class Product < ActiveRecord::Base
  has_many :categorisations
  has_many :categories, :through => :categorisations

  ThinkingSphinx::Callbacks.append(self, :behaviours => [:real_time])
end
