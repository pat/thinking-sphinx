%w( rover lassie gaspode ).each do |name|
  Dog.new(:name => name).save(:validate => false)
end
