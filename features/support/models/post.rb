class Post < ActiveRecord::Base
  has_many :comments
  
  define_index do
    indexes subject
    indexes content
  end
end