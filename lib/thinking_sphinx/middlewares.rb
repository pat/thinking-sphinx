# frozen_string_literal: true

module ThinkingSphinx::Middlewares; end

%w[
  middleware active_record_translator attribute_typer geographer glazier
  ids_only inquirer sphinxql stale_id_checker stale_id_filter utf8 valid_options
].each do |middleware|
  require "thinking_sphinx/middlewares/#{middleware}"
end

module ThinkingSphinx::Middlewares
  def self.use(builder, middlewares)
    middlewares.each { |m| builder.use m }
  end

  BASE_MIDDLEWARES = [ValidOptions, AttributeTyper, SphinxQL, Geographer, Inquirer]

  DEFAULT = ::Middleware::Builder.new do
    use StaleIdFilter
    ThinkingSphinx::Middlewares.use self, BASE_MIDDLEWARES
    use ActiveRecordTranslator
    use StaleIdChecker
    use Glazier
  end

  RAW_ONLY = ::Middleware::Builder.new do
    ThinkingSphinx::Middlewares.use self, BASE_MIDDLEWARES
  end

  IDS_ONLY = ::Middleware::Builder.new do
    ThinkingSphinx::Middlewares.use self, BASE_MIDDLEWARES
    use IdsOnly
  end
end
