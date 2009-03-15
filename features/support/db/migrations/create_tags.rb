ActiveRecord::Base.connection.create_table :tags, :force => true do |t|
  # t.column :post_id, :integer, :null => false
  t.column :text,       :text,  :null => true
end

post = Post.find(1)

[
  'Nunc in neque. Integer sed odio ac quam pellentesque suscipit. Cras posuere posuere est. Suspendisse est.',
  'In hac habitasse platea dictumst. Etiam eleifend est ac diam. Ut ac felis sit amet mi bibendum varius.',
  'Nullam sollicitudin tellus at ipsum. Duis mi eros, blandit sed, condimentum non, mattis vel, orci.',
  'Praesent auctor mollis leo. Nulla facilisi. Pellentesque habitant morbi tristique senectus et netus et',
  'malesuada fames ac turpis egestas. Donec non odio. Maecenas varius elit ut ante. Phasellus egestas, quam',
  'a congue euismod, diam urna gravida risus, at euismod lectus diam id sem. Vestibulum sed dolor et massa',
  'porta placerat. Etiam eget risus. Sed ornare. Vivamus in sapien. Maecenas non enim nec metus posuere',
  'vehicula. Donec rhoncus mauris at metus. Curabitur volutpat massa a metus. Aliquam ornare, neque ut',
  'tristique convallis, libero orci eleifend nibh, ac porta leo felis sed orci. Lorem ipsum dolor sit amet,',
  'Waffles' # This one is important, whereas the others are just padding
].each do |text|
  Tagging.create :taggable => post, :tag => Tag.create(:text => text)
end

Developer.find(:all).each do |developer|
  [:country, :city, :state].each do |column|
    Tagging.create(
      :taggable => developer,
      :tag => Tag.find_or_create_by_text(developer.send(column))
    )
  end
end
