require 'riddle'
require 'blankslate'
require 'middleware'
require 'active_record'

module ThinkingSphinx
  def self.count(query = '', options = {})
    search(query, options).total_entries
  end

  def self.search(query = '', options = {})
    ThinkingSphinx::Search.new query, options
  end
end

# Core
require 'thinking_sphinx/callbacks'
require 'thinking_sphinx/core'
require 'thinking_sphinx/configuration'
require 'thinking_sphinx/excerpter'
require 'thinking_sphinx/index'
require 'thinking_sphinx/middlewares'
require 'thinking_sphinx/rake_interface'
require 'thinking_sphinx/scopes'
require 'thinking_sphinx/search'
require 'thinking_sphinx/version'
# Extended
require 'thinking_sphinx/active_record'
require 'thinking_sphinx/deltas'
require 'thinking_sphinx/real_time'

require 'thinking_sphinx/railtie' if defined?(Rails)
