if defined?(Capistrano::VERSION)
  major_version = Gem::Version.new(Capistrano::VERSION).segments.first
  require_relative "capistrano/v#{major_version}"
end
