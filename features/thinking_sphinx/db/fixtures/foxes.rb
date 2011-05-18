%w( fantastic ).each do |name|
  Fox.new(:name => name).save(:validate => false)
end
