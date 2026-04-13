# frozen_string_literal: true

case ENV["DATABASE"]
when "trilogy"
  ThinkingSphinx::Connection.connection_class = ThinkingSphinx::Connection::Trilogy
when "jruby"
  ThinkingSphinx::Connection.connection_class = ThinkingSphinx::Connection::JRuby 
when "mysql2"
  ThinkingSphinx::Connection.connection_class = ThinkingSphinx::Connection::Mysql2
else
  # rely on the default connection_class lookup
end



