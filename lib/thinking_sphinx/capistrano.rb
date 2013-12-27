if defined?(Capistrano::VERSION)
  capistrano_version = Gem::Version.new(Capistrano::VERSION).segments.first
  recipe_version = capistrano_version < 2 ? 2 : capistrano_version
  require_relative "capistrano/v#{recipe_version}"
end
