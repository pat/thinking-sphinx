module SphinxYamlHelpers
  def write_configuration(hash)
    File.stub :read => {'test' => hash}.to_yaml, :exists? => true
  end
end

RSpec.configure do |config|
  config.include SphinxYamlHelpers
end