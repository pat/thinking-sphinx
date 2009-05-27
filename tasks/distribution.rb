require 'rake/rdoctask'
require 'rake/gempackagetask'

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'thinking_sphinx'

desc 'Generate documentation'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Thinking Sphinx - ActiveRecord Sphinx Plugin'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name              = "thinking-sphinx"
  s.version           = ThinkingSphinx::Version::String
  s.summary           = "A concise and easy-to-use Ruby library that connects ActiveRecord to the Sphinx search daemon, managing configuration, indexing and searching."
  s.description       = "A concise and easy-to-use Ruby library that connects ActiveRecord to the Sphinx search daemon, managing configuration, indexing and searching."
  s.author            = "Pat Allan"
  s.email             = "pat@freelancing-gods.com"
  s.homepage          = "http://ts.freelancing-gods.com"
  s.has_rdoc          = true
  s.rdoc_options     << "--title" << "Thinking Sphinx -- Rails/Merb Sphinx Plugin" <<
                        "--line-numbers"
  s.rubyforge_project = "thinking-sphinx"
  s.test_files        = FileList["spec/**/*_spec.rb"]
  s.files             = FileList[
    "lib/**/*.rb",
    "LICENCE",
    "README.textile",
    "tasks/**/*.rb",
    "tasks/**/*.rake",
    "vendor/**/*"
  ]
  s.post_install_message = <<-MESSAGE
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

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

desc "Build gemspec file"
task :build do
  File.open('thinking-sphinx.gemspec', 'w') { |f| f.write spec.to_ruby }
end
