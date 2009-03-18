require 'active_record'
Database = defined?(JRUBY_VERSION) ? 'jdbcmysql' : 'mysql'
require "active_record/connection_adapters/#{Database}_adapter"
