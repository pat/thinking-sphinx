ActiveRecord::Schema.define do
  create_table(:articles, :force => true) do |t|
    t.string  :title
    t.text    :content
    t.boolean :published
    t.timestamps
  end

  create_table(:books, :force => true) do |t|
    t.string :title
    t.string :author
    t.timestamps
  end
end
