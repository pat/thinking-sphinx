%w( fantastic ).each do |name|
  Fox.new(:name => name).save(false)
end
