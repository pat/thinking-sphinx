ActiveRecord::Base.connection.create_table :comments, :force => true do |t|
  t.column :name,     :string,  :null => false
  t.column :email,    :string
  t.column :url,      :string
  t.column :content,  :text
  t.column :post_id,  :integer, :null => false
  t.column :category_id, :integer, :null => false
end

Comment.create(
  :name     => "Pat",
  :content  => "+1",
  :post_id  => 1,
  :category_id => 1
)

Comment.create(
  :name     => "Menno",
  :content  => "Second post!",
  :post_id  => 1
)

Comment.create :name => 'A', :post_id => 1, :content => 'Es un hecho establecido hace demasiado tiempo que un lector se distraerá con el contenido del texto'
Comment.create :name => 'B', :post_id => 1, :content => 'de un sitio mientras que mira su diseño. El punto de usar Lorem Ipsum es que tiene una distribución'
Comment.create :name => 'C', :post_id => 1, :content => 'más o menos normal de las letras, al contrario de usar textos como por ejemplo "Contenido aquí'
Comment.create :name => 'D', :post_id => 1, :content => 'contenido aquí". Estos textos hacen parecerlo un español que se puede leer. Muchos paquetes de'
Comment.create :name => 'E', :post_id => 1, :content => 'autoedición y editores de páginas web usan el Lorem Ipsum como su texto por defecto, y al hacer una'
Comment.create :name => 'F', :post_id => 1, :content => 'búsqueda de "Lorem Ipsum" va a dar por resultado muchos sitios web que usan este texto si se'

# The one we'll really want to find via Sphinx search
Comment.create :name => 'G', :post_id => 1, :content => 'Turtle'
