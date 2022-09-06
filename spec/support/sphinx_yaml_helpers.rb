# frozen_string_literal: true

module SphinxYamlHelpers
  def write_configuration(hash)
    allow(File).to receive(:read).and_return({'test' => hash}.to_yaml)
    allow(File).to receive(:exist?).and_wrap_original do |original, path|
      next true if path.to_s == File.absolute_path("config/thinking_sphinx.yml", Rails.root.to_s)

      original.call(path)
    end
  end
end

RSpec.configure do |config|
  config.include SphinxYamlHelpers
end
