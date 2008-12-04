Given "Sphinx is running" do
  ThinkingSphinx::Configuration.instance.controller.should be_running
end

When "I wait for Sphinx to catch up" do
  sleep(0.25)
end