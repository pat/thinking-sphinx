Given /^a post with subject "(.+)"$/ do |subject|
  Post.create!(:subject => subject)
end

Given /^the "(.+)" post has the following (.+):$/ do |subject, resource, attribute_table|
  post = Post.find_by_subject(subject)
  attribute_table.hashes.each do |hash|
    post.send(resource).create!(hash)
  end
end
