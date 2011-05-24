class Music < Medium
  set_table_name 'music'
  
  define_index do
    indexes artist, :with => :attribute
    indexes track
    indexes album, :with => :wordcount
    indexes genre(:name), :as => :genre
  end
end
