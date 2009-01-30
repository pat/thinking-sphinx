class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :category
  
  define_index do 
    indexes :content
    
    has category.name, :facet => true, :as => :category_name, :type => :string
  end
end
