%w(
  one two three four five six seven eight nine ten
).each_with_index do |number, index|
  value = index + 1
  cost  = value.to_f + 0.5 + (value * 0.01)
  Alpha.create :name => number, :value => value, :cost => cost,
    :created_on => value.days.ago.to_date, :created_at => value.days.ago
end
