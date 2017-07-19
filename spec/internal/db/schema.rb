ActiveRecord::Schema.define do
  create_table(:admin_people, :force => true) do |t|
    t.string :name
    t.timestamps null: false
  end

  create_table(:albums, :force => true, :id => false) do |t|
    t.string :id
    t.integer :integer_id
    t.string :name
    t.string :artist
    t.boolean :delta, :default => true, :null => false
  end

  create_table(:animals, :force => true) do |t|
    t.string :name
    t.string :type
  end

  create_table(:articles, :force => true) do |t|
    t.string  :title
    t.text    :content
    t.boolean :published
    t.integer :user_id
    t.timestamps null: false
  end

  create_table(:manufacturers, :force => true) do |t|
    t.string  :name
  end

  create_table(:cars, :force => true) do |t|
    t.integer :manufacturer_id
    t.string  :name
  end

  create_table(:books, :force => true) do |t|
    t.string  :title
    t.string  :author
    t.integer :year
    t.string  :blurb_file
    t.boolean :delta, :default => true,   :null => false
    t.string  :type,  :default => 'Book', :null => false
    t.timestamps null: false
  end

  create_table(:books_genres, :force => true, :id => false) do |t|
    t.integer :book_id
    t.integer :genre_id
  end

  create_table(:categories, :force => true) do |t|
    t.string :name
  end

  create_table(:categorisations, :force => true) do |t|
    t.integer :category_id
    t.integer :product_id
  end

  create_table(:cities, :force => true) do |t|
    t.string :name
    t.float  :lat
    t.float  :lng
  end

  create_table(:colours, :force => true) do |t|
    t.string :name
    t.timestamps null: false
  end

  create_table(:events, :force => true) do |t|
    t.string  :eventable_type
    t.integer :eventable_id
  end

  create_table(:genres, :force => true) do |t|
    t.string :name
  end

  create_table(:products, :force => true) do |t|
    t.string :name
    t.json :options if ::JSONColumn.call
  end

  create_table(:taggings, :force => true) do |t|
    t.integer :tag_id
    t.integer :article_id
    t.timestamps null: false
  end

  create_table(:tags, :force => true) do |t|
    t.string :name
    t.timestamps null: false
  end

  create_table(:tees, :force => true) do |t|
    t.integer :colour_id
    t.timestamps null: false
  end

  create_table(:tweets, :force => true, :id => false) do |t|
    t.column :id, :bigint, :null => false
    t.string :text
    t.timestamps null: false
  end

  create_table(:users, :force => true) do |t|
    t.string :name
    t.timestamps null: false
  end
end
