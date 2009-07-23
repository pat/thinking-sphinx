Given "Sphinx is running" do
  ThinkingSphinx::Configuration.instance.controller.should be_running
end

When "I kill the Sphinx process" do
  Process.kill(9, ThinkingSphinx.sphinx_pid.to_i)
end

When "I wait for Sphinx to catch up" do
  sleep(0.25)
end

When /^I start Sphinx/ do
  ThinkingSphinx::Configuration.instance.controller.start
end

When "I stop Sphinx" do
  ThinkingSphinx::Configuration.instance.controller.stop
end

Then /^Sphinx should be running/ do
  ThinkingSphinx.sphinx_running?.should be_true
end

Then "Sphinx should not be running" do
  ThinkingSphinx.sphinx_running?.should be_false
end
