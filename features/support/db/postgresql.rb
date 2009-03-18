require 'active_record'
Database = defined?(JRUBY_VERSION) ? 'jdbcpostgresql' : 'postgresql'
require "active_record/connection_adapters/#{Database}_adapter"
