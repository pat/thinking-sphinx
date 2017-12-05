# frozen_string_literal: true

# New versions of MySQL don't allow NULL values for primary keys, but old
# versions of Rails do. To use both at the same time, we need to update Rails'
# default primary key type to no longer have a default NULL value.
#
class PatchAdapter
  def call
    return unless using_mysql? && using_rails_pre_4_1?

    require 'active_record/connection_adapters/abstract_mysql_adapter'
    ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::
      NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
  end

  def using_mysql?
    ENV.fetch('DATABASE', 'mysql2') == 'mysql2'
  end

  def using_rails_pre_4_1?
    ActiveRecord::VERSION::STRING.to_f < 4.1
  end
end

PatchAdapter.new.call
