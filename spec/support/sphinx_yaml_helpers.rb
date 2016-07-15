module SphinxYamlHelpers
  def write_configuration(hash)
    allow(File).to receive_messages :read => {'test' => hash}.to_yaml, :exists? => true
  end
end

RSpec.configure do |config|
  config.include SphinxYamlHelpers
end
