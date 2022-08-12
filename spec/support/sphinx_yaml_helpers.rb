# frozen_string_literal: true

module SphinxYamlHelpers
  def write_configuration(hash)
    allow(File).to receive_messages :read => {'test' => hash}.to_yaml, :exist? => true, :exists? => true
  end
end

RSpec.configure do |config|
  config.include SphinxYamlHelpers
end
