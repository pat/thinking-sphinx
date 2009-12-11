class Music < Medium
  set_table_name 'music'
  
  define_index do
    indexes artist, track, album
    indexes genre(:name), :as => :genre
  end
end
