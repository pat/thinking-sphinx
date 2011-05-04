module ThinkingSphinx
  module HashExcept
    # Returns a new hash without the given keys.
    def except(*keys)
      rejected = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
      reject { |key,| rejected.include?(key) }
    end

    # Replaces the hash without only the given keys.
    def except!(*keys)
      replace(except(*keys))
    end
  end
end

Hash.send(
  :include, ThinkingSphinx::HashExcept
) unless Hash.instance_methods.include?("except")

module ThinkingSphinx
  module ArrayExtractOptions
    def extract_options!
      last.is_a?(::Hash) ? pop : {}
    end
  end
end

Array.send(
  :include, ThinkingSphinx::ArrayExtractOptions
) unless Array.instance_methods.include?("extract_options!")

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

module ThinkingSphinx
  module ClassAttributeMethods
    def cattr_reader(*syms)
      syms.flatten.each do |sym|
        next if sym.is_a?(Hash)
        class_eval(<<-EOS, __FILE__, __LINE__)
          unless defined? @@#{sym}
            @@#{sym} = nil
          end

          def self.#{sym}
            @@#{sym}
          end

          def #{sym}
            @@#{sym}
          end
        EOS
      end
    end

    def cattr_writer(*syms)
      options = syms.extract_options!
      syms.flatten.each do |sym|
        class_eval(<<-EOS, __FILE__, __LINE__)
          unless defined? @@#{sym}
            @@#{sym} = nil
          end

          def self.#{sym}=(obj)
            @@#{sym} = obj
          end

          #{"
          def #{sym}=(obj)
            @@#{sym} = obj
          end
          " unless options[:instance_writer] == false }
        EOS
      end
    end

    def cattr_accessor(*syms)
      cattr_reader(*syms)
      cattr_writer(*syms)
    end
  end
end

Class.extend(
  ThinkingSphinx::ClassAttributeMethods
) unless Class.respond_to?(:cattr_reader)

module ThinkingSphinx
  module SingletonClass
    def singleton_class
      class << self
        self
      end
    end
  end
end

unless Object.new.respond_to?(:singleton_class)
  Object.send(:include, ThinkingSphinx::SingletonClass)
end

module ThinkingSphinx
  module ObjectTry
    def try(*a, &b)
      if a.empty? && block_given?
        yield self
      else
        __send__(*a, &b)
      end
    end
  end

  module NilClassTry
    def try(*args)
      nil
    end
  end
end

Object.send(:include, ThinkingSphinx::ObjectTry) unless Object.new.respond_to?(:try)
NilClass.send(:include, ThinkingSphinx::NilClassTry) unless nil.respond_to?(:try)

module ThinkingSphinx
  module EnumerableOne
    def one?(&block)
      select(&block).size == 1
    end
  end
end

Enumerable.send(:include, ThinkingSphinx::EnumerableOne) unless [].respond_to?(:one?)