class City < ActiveRecord::Base
  scope :ordered, order(:name)
end
