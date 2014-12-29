require 'active_record'
require 'joiner'

module ThinkingSphinx::ActiveRecord
  module Callbacks; end
end

require 'thinking_sphinx/active_record/property'
require 'thinking_sphinx/active_record/association'
require 'thinking_sphinx/active_record/association_proxy'
require 'thinking_sphinx/active_record/attribute'
require 'thinking_sphinx/active_record/base'
require 'thinking_sphinx/active_record/column'
require 'thinking_sphinx/active_record/column_sql_presenter'
require 'thinking_sphinx/active_record/database_adapters'
require 'thinking_sphinx/active_record/field'
require 'thinking_sphinx/active_record/filter_reflection'
require 'thinking_sphinx/active_record/index'
require 'thinking_sphinx/active_record/interpreter'
require 'thinking_sphinx/active_record/join_association'
require 'thinking_sphinx/active_record/log_subscriber'
require 'thinking_sphinx/active_record/polymorpher'
require 'thinking_sphinx/active_record/property_query'
require 'thinking_sphinx/active_record/property_sql_presenter'
require 'thinking_sphinx/active_record/simple_many_query'
require 'thinking_sphinx/active_record/sql_builder'
require 'thinking_sphinx/active_record/sql_source'

require 'thinking_sphinx/active_record/callbacks/delete_callbacks'
require 'thinking_sphinx/active_record/callbacks/delta_callbacks'
require 'thinking_sphinx/active_record/callbacks/update_callbacks'
