(1..10).each do |i|
  Box.create :width => i, :length => i, :depth => i
end

(11..20).each do |i|
  Box.create :width => i, :length => i+1, :depth => i+2
end
