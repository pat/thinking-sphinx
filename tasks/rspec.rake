begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  require 'spec'
end

begin
  require 'spec/rake/spectask'
rescue LoadError
  puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
  exit(0)
end

# allow require of spec/spec_helper
$:.unshift File.dirname(__FILE__) + '/../'

desc "Run the specs under spec"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end