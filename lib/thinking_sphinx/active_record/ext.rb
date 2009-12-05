module ThinkingSphinx
  module AbstractQuotedTableName
    def quote_table_name(name)
      quote_column_name(name)
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(
  :include, ThinkingSphinx::AbstractQuotedTableName
) unless ActiveRecord::ConnectionAdapters::AbstractAdapter.instance_methods.include?("quote_table_name")

module ThinkingSphinx
  module MysqlQuotedTableName
    def quote_table_name(name) #:nodoc:
      quote_column_name(name).gsub('.', '`.`')
    end
  end
end

if ActiveRecord::ConnectionAdapters.constants.include?("MysqlAdapter") or ActiveRecord::Base.respond_to?(:jdbcmysql_connection)
  adapter = ActiveRecord::ConnectionAdapters.const_get(
    defined?(JRUBY_VERSION) ? :JdbcAdapter : :MysqlAdapter
  )
  unless adapter.instance_methods.include?("quote_table_name")
    adapter.send(:include, ThinkingSphinx::MysqlQuotedTableName)
  end
end

module ThinkingSphinx
  module ActiveRecordQuotedName
    def quoted_table_name
      self.connection.quote_table_name(self.table_name)
    end 
  end
end

ActiveRecord::Base.extend(
  ThinkingSphinx::ActiveRecordQuotedName
) unless ActiveRecord::Base.respond_to?("quoted_table_name")

module ThinkingSphinx
  module ActiveRecordStoreFullSTIClass
    def store_full_sti_class
      false
    end
  end
end

ActiveRecord::Base.extend(
  ThinkingSphinx::ActiveRecordStoreFullSTIClass
) unless ActiveRecord::Base.respond_to?(:store_full_sti_class)
