class Category < ActiveRecord::Base
  has_many :categorisations
  has_many :products, :through => :categorisations
end
