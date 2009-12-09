class Review
  include DataMapper::Resource
  include ThinkingSphinx::Base
  include ThinkingSphinx::DataMapper
  
  property :id,      Serial
  property :title,   String
  property :content, Text
  property :rating,  Integer
  property :book_id, Integer
end
