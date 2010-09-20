require 'yard'
require 'jeweler'

desc 'Generate documentation'
YARD::Rake::YardocTask.new

Jeweler::Tasks.new do |gem|
  gem.name        = "thinking-sphinx"
  gem.summary     = "ActiveRecord/Rails Sphinx library"
  gem.description = "A concise and easy-to-use Ruby library that connects ActiveRecord to the Sphinx search daemon, managing configuration, indexing and searching."
  gem.author      = "Pat Allan"
  gem.email       = "pat@freelancing-gods.com"
  gem.homepage    = "http://ts.freelancing-gods.com"
    
  # s.rubyforge_project = "thinking-sphinx"
  gem.files     = FileList[
    "rails/*.rb",
    "lib/**/*.rb",
    "LICENCE",
    "README.textile",
    "tasks/**/*.rb",
    "VERSION"
  ]
  gem.test_files = FileList[
    "features/**/*.rb",
    "features/**/*.feature",
    "features/**/*.example.yml",
    "spec/**/*_spec.rb"
  ]
  
  gem.post_install_message = <<-MESSAGE
If you're upgrading, you should read this:
http://freelancing-god.github.com/ts/en/upgrading.html

MESSAGE
end
