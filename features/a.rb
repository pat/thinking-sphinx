# This file exists because Cucumber likes to auto-load all ruby files
puts <<-MESSAGE
Cucumber defaults to loading all ruby files within the features folder. This is
annoying, because some files need to be loaded before others (and others
perhaps not at all, given missing dependencies). Hence this place-holder
imaginatively named 'a.rb', to force this message.

A work-around is to use cucumber profiles. You will find the default profile in
cucumber.yml should serve your needs fine, unless you add new step definitions.
When you do that, you can regenerate the YAML file by running:
rake cucumber_defaults

And then run specific features as follows is slightly more verbose, but it
works, whereas this doesn't.
cucumber -p default features/something.feature
MESSAGE
exit 0