class Comment < ActiveRecord::Base
  define_index do 
    indexes :content
    
    has category.name, :facet => true, :as => :category_name, :type => :string
  end
  
  belongs_to :post
  belongs_to :category
end
