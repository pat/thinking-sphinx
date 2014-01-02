class City < ActiveRecord::Base
  scope :ordered, lambda { order(:name) }
end
