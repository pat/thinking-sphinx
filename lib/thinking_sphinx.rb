if RUBY_PLATFORM == 'java'
  require 'java'
  require 'jdbc/mysql'
else
  require 'mysql2'
end

require 'riddle'
require 'middleware'
require 'active_record'

module ThinkingSphinx
  def self.count(query = '', options = {})
    search(query, options).total_entries
  end

  def self.facets(query = '', options = {})
    ThinkingSphinx::FacetSearch.new query, options
  end

  def self.search(query = '', options = {})
    ThinkingSphinx::Search.new query, options
  end

  def self.search_for_ids(query = '', options = {})
    search = ThinkingSphinx::Search.new query, options
    ThinkingSphinx::Search::Merger.new(search).merge! nil, :ids_only => true
  end
end

# Core
require 'thinking_sphinx/batched_search'
require 'thinking_sphinx/callbacks'
require 'thinking_sphinx/core'
require 'thinking_sphinx/configuration'
require 'thinking_sphinx/connection'
require 'thinking_sphinx/excerpter'
require 'thinking_sphinx/facet'
require 'thinking_sphinx/facet_search'
require 'thinking_sphinx/frameworks'
require 'thinking_sphinx/index'
require 'thinking_sphinx/index_set'
require 'thinking_sphinx/masks'
require 'thinking_sphinx/middlewares'
require 'thinking_sphinx/panes'
require 'thinking_sphinx/rake_interface'
require 'thinking_sphinx/scopes'
require 'thinking_sphinx/search'
require 'thinking_sphinx/test'
# Extended
require 'thinking_sphinx/active_record'
require 'thinking_sphinx/deltas'
require 'thinking_sphinx/real_time'

require 'thinking_sphinx/railtie' if defined?(Rails)
