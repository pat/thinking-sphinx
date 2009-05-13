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
  puts   "rake features:mysql"
  system "rake features:mysql"
  puts   "rake features:postgresql"
  system "rake features:postgresql"
end

namespace :features do
  def add_task(name, description)
    Cucumber::Rake::Task.new(name, description) do |t|
      t.cucumber_opts = "--format pretty"
      t.profile = name
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
  t.rcov_opts = ['--exclude', 'spec', '--exclude', 'gems', '--exclude', 'riddle']
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
  default_requires = %w(
    --require features/support/env.rb
    --require features/support/db/mysql.rb
    --require features/support/db/active_record.rb
    --require features/support/post_database.rb
  ).join(" ")
  
  step_definitions = FileList["features/step_definitions/**.rb"].collect { |path|
    "--require #{path}"
  }.join(" ")
  
  features = FileList["features/*.feature"].join(" ")
  
  File.open('cucumber.yml', 'w') { |f|
    f.write "default: \"#{default_requires} #{step_definitions}\"\n\n"
    f.write "mysql: \"#{default_requires} #{step_definitions} #{features}\"\n\n"
    f.write "postgresql: \"#{default_requires.gsub(/mysql/, 'postgresql')} #{step_definitions} #{features}\""
  }
end
