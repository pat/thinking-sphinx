class Book
  include DataMapper::Resource
  include ThinkingSphinx::Base
  include ThinkingSphinx::DataMapper
  
  property :id,     Serial
  property :title,  String
  property :author, String
  property :delta,  Boolean
  
  has n, :reviews
  
  define_index do
    indexes title
    indexes author
    indexes reviews.content, :as => :reviews
    
    set_property :delta => true
  end
end
