class Book
  include DataMapper::Resource
  include ThinkingSphinx::Base
  include ThinkingSphinx::DataMapper
  
  property :id,     Serial
  property :title,  String
  property :author, String
  property :delta,  Boolean
  
  define_index do
    indexes title
    indexes author
    
    set_property :delta => true
  end
end
