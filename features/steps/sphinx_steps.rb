Given "Sphinx is running" do
  ThinkingSphinx::Configuration.instance.controller.should be_running
end
