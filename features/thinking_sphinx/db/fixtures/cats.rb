%w( rogue nat molly jasper moggy ).each do |name|
  Cat.new(:name => name).save(false)
end
