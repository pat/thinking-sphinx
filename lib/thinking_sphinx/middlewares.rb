module ThinkingSphinx::Middlewares
  #
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

ThinkingSphinx::Middlewares::DEFAULT = ::Middleware::Builder.new do
  use ThinkingSphinx::Middlewares::StaleIdFilter
  use ThinkingSphinx::Middlewares::SphinxQL
  use ThinkingSphinx::Middlewares::Geographer
  use ThinkingSphinx::Middlewares::Inquirer
  use ThinkingSphinx::Middlewares::ActiveRecordTranslator
  use ThinkingSphinx::Middlewares::StaleIdChecker
  use ThinkingSphinx::Middlewares::Glazier
end

ThinkingSphinx::Middlewares::IDS_ONLY = ::Middleware::Builder.new do
  use ThinkingSphinx::Middlewares::SphinxQL
  use ThinkingSphinx::Middlewares::Geographer
  use ThinkingSphinx::Middlewares::Inquirer
  use ThinkingSphinx::Middlewares::IdsOnly
end
