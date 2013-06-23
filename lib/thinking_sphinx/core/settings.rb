module ThinkingSphinx::Core::Settings
  private
  def apply_defaults!(defaults = self.class.settings)
    defaults.each do |setting|
      value = config.settings[setting.to_s]
      send("#{setting}=", value) unless value.nil?
    end
  end
end
