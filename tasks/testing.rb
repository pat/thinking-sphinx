require 'rubygems'
require 'spec/rake/spectask'
require 'cucumber/rake/task'

desc "Run the specs under spec"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts << "-c"
end

desc "Run all feature-set configurations"
task :features do |t|
  databases = ENV['DATABASES'] || 'mysql,postgresql'
  databases.split(',').each do |database|
    puts   "rake features:#{database}"
    system "rake features:#{database}"
  end
end

namespace :features do
  def add_task(name, description)
    Cucumber::Rake::Task.new(name, description) do |t|
      t.cucumber_opts = "--format pretty features/*.feature DATABASE=#{name}"
    end
  end
  
  add_task :mysql,      "Run feature-set against MySQL"
  add_task :postgresql, "Run feature-set against PostgreSQL"
end

desc "Generate RCov reports"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.libs << 'lib'
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = [
    '--exclude', 'spec',
    '--exclude', 'gems',
    '--exclude', 'riddle',
    '--exclude', 'ruby'
  ]
end

namespace :rcov do
  def add_task(name, description)
    Cucumber::Rake::Task.new(name, description) do |t|
      t.cucumber_opts = "--format pretty"
      t.profile = name
      t.rcov = true
      t.rcov_opts = [
        '--exclude', 'spec',
        '--exclude', 'gems',
        '--exclude', 'riddle',
        '--exclude', 'features'
      ]
    end
  end
  
  add_task :mysql,      "Run feature-set against MySQL with rcov"
  add_task :postgresql, "Run feature-set against PostgreSQL with rcov"
end

desc "Build cucumber.yml file"
task :cucumber_defaults do
  steps = FileList["features/step_definitions/**.rb"].collect { |path|
    "--require #{path}"
  }.join(" ")
  
  File.open('cucumber.yml', 'w') { |f|
    f.write "default: \"--require features/support/env.rb #{steps}\"\n"
  }
end
