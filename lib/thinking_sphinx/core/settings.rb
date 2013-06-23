module ThinkingSphinx::Core::Settings
  private
  def apply_defaults!
    self.class.settings.each do |setting|
      value = config.settings[setting.to_s]
      send("#{setting}=", value) unless value.nil?
    end
  end
end
