# frozen_string_literal: true

if defined?(Capistrano::VERSION)
  if Gem::Version.new(Capistrano::VERSION).release >= Gem::Version.new('3.0.0')
    recipe_version = 3
  end
end

recipe_version ||= 2
require_relative "capistrano/v#{recipe_version}"
