post = Post.create(
  :subject => "Hello World",
  :content => "Um Text",
  :id => 1,
  :category_id => 1,
  :keywords_file => (File.dirname(__FILE__) + '/post_keywords.txt')
)

post.authors << Author.find(:first)
post.save
