module ThinkingSphinx::Middlewares
  def self.stack_from_array(array)
    ::Middleware::Builder.new do
      array.each { |mw| use mw }
    end
  end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/active_record_translator'
require 'thinking_sphinx/middlewares/geographer'
require 'thinking_sphinx/middlewares/glazier'
require 'thinking_sphinx/middlewares/ids_only'
require 'thinking_sphinx/middlewares/inquirer'
require 'thinking_sphinx/middlewares/sphinxql'
require 'thinking_sphinx/middlewares/stale_id_checker'
require 'thinking_sphinx/middlewares/stale_id_filter'

ThinkingSphinx::Middlewares::DEFAULT = [
  ThinkingSphinx::Middlewares::StaleIdFilter,
  ThinkingSphinx::Middlewares::SphinxQL,
  ThinkingSphinx::Middlewares::Geographer,
  ThinkingSphinx::Middlewares::Inquirer,
  ThinkingSphinx::Middlewares::ActiveRecordTranslator,
  ThinkingSphinx::Middlewares::StaleIdChecker,
  ThinkingSphinx::Middlewares::Glazier
]

ThinkingSphinx::Middlewares::IDS_ONLY = [
  ThinkingSphinx::Middlewares::SphinxQL,
  ThinkingSphinx::Middlewares::Geographer,
  ThinkingSphinx::Middlewares::Inquirer,
  ThinkingSphinx::Middlewares::IdsOnly
]
