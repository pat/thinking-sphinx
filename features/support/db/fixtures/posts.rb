post = Post.create(
  :subject => "Hello World", :content => "Um Text", :id => 1, :category_id => 1
)

post.authors << Author.find(:first)
post.save
