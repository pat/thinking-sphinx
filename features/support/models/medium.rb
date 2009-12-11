class Medium < ActiveRecord::Base
  self.abstract_class = true
  
  belongs_to :genre
end
