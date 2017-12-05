# frozen_string_literal: true

class City < ActiveRecord::Base
  scope :ordered, lambda { order(:name) }
end
