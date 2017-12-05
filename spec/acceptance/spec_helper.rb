# frozen_string_literal: true

require 'spec_helper'

root = File.expand_path File.dirname(__FILE__)
Dir["#{root}/support/**/*.rb"].each { |file| require file }

if ENV['SPHINX_VERSION'].try :[], /2.0.\d/
  ThinkingSphinx::SphinxQL.variables!

  ThinkingSphinx::Middlewares::DEFAULT.insert_after(
    ThinkingSphinx::Middlewares::Inquirer,
    ThinkingSphinx::Middlewares::UTF8
  )
  ThinkingSphinx::Middlewares::RAW_ONLY.insert_after(
    ThinkingSphinx::Middlewares::Inquirer,
    ThinkingSphinx::Middlewares::UTF8
  )
end
