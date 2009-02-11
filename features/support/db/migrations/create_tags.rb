ActiveRecord::Base.connection.create_table :tags, :force => true do |t|
  t.column :post_id, :integer, :null => false
  t.column :text,       :text,  :null => true
end

Tag.create :post_id => 1, :text => 'Nunc in neque. Integer sed odio ac quam pellentesque suscipit. Cras posuere posuere est. Suspendisse est.'
Tag.create :post_id => 1, :text => 'In hac habitasse platea dictumst. Etiam eleifend est ac diam. Ut ac felis sit amet mi bibendum varius.'
Tag.create :post_id => 1, :text => 'Nullam sollicitudin tellus at ipsum. Duis mi eros, blandit sed, condimentum non, mattis vel, orci.'
Tag.create :post_id => 1, :text => 'Praesent auctor mollis leo. Nulla facilisi. Pellentesque habitant morbi tristique senectus et netus et'
Tag.create :post_id => 1, :text => 'malesuada fames ac turpis egestas. Donec non odio. Maecenas varius elit ut ante. Phasellus egestas, quam'
Tag.create :post_id => 1, :text => 'a congue euismod, diam urna gravida risus, at euismod lectus diam id sem. Vestibulum sed dolor et massa'
Tag.create :post_id => 1, :text => 'porta placerat. Etiam eget risus. Sed ornare. Vivamus in sapien. Maecenas non enim nec metus posuere'
Tag.create :post_id => 1, :text => 'vehicula. Donec rhoncus mauris at metus. Curabitur volutpat massa a metus. Aliquam ornare, neque ut'
Tag.create :post_id => 1, :text => 'tristique convallis, libero orci eleifend nibh, ac porta leo felis sed orci. Lorem ipsum dolor sit amet,'

# The one we'll really want to find via Sphinx search
Tag.create :post_id => 1, :text => 'Waffles'
