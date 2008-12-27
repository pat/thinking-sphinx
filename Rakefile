begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  require 'spec'
end

require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'rake/gempackagetask'
require 'cucumber/rake/task'

# allow require of spec/spec_helper
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../'
$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

require 'thinking_sphinx'

desc 'Generate documentation'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Thinking Sphinx - ActiveRecord Sphinx Plugin'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Run the specs under spec"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts << "-c"
end

desc "Run all feature-set configurations"
task :features do
  # 
end

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "--format progress"
  t.step_pattern  = ["features/support/env", "features/step_definitions/**.rb"]
end

namespace :features do
  Cucumber::Rake::Task.new(:mysql, "Run feature-set against MySQL") do |t|
    t.libs         << "features/fixtures/setup_mysql"
    t.cucumber_opts = "--format pretty"
  end
  
  Cucumber::Rake::Task.new(:postgres, "Run feature-set against PostgreSQL") do |t|
    t.cucumber_opts = "--format pretty"
  end
end

desc "Generate RCov reports"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.libs << 'lib'
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec', '--exclude', 'gems', '--exclude', 'riddle']
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
    "README",
    "tasks/**/*.rb",
    "tasks/**/*.rake",
    "vendor/**/*"
  ]
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

desc "Build cucumber.yml file"
task :cucumber_defaults do
  step_definitions = FileList["features/step_definitions/**.rb"].collect { |path|
    "--require #{path}"
  }.join(" ")
  
  File.open('cucumber.yml', 'w') { |f|
    f.write "default: \"--require features/support/env.rb #{step_definitions}\""
  }
end
