{
  'F0001' => 'Fritz',
  'S0001' => 'Sizzle',
  'S0002' => 'Sizzle Jr.',
  'E0001' => 'Expendable'
}.each do |internal_id, name|
  Robot.connection.execute "INSERT INTO robots (name, internal_id) VALUES ('#{name}', '#{internal_id}')"
end
