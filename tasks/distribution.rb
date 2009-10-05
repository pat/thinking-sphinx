require 'yard'
require 'jeweler'

desc 'Generate documentation'
YARD::Rake::YardocTask.new do |t|
  # t.title = 'Thinking Sphinx - ActiveRecord Sphinx Plugin'
end

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
    "tasks/**/*.rake",
    "vendor/**/*",
    "VERSION.yml"
  ]
  gem.test_files = FileList["spec/**/*_spec.rb"]
  
  gem.add_dependency 'activerecord', '>= 1.15.6'
  
  gem.post_install_message = <<-MESSAGE
With the release of Thinking Sphinx 1.1.18, there is one important change to
note: previously, the default morphology for indexing was 'stem_en'. The new
default is nil, to avoid any unexpected behavior. If you wish to keep the old
value though, you will need to add the following settings to your
config/sphinx.yml file:

development:
  morphology: stem_en
test:
  morphology: stem_en
production:
  morphology: stem_en

To understand morphologies/stemmers better, visit the following link:
http://www.sphinxsearch.com/docs/manual-0.9.8.html#conf-morphology

MESSAGE
end
