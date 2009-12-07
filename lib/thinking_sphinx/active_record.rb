require 'after_commit'

require 'thinking_sphinx/active_record/ext'
require 'thinking_sphinx/active_record/attribute_updates'
require 'thinking_sphinx/active_record/has_many_association'
require 'thinking_sphinx/active_record/tailor'

# Core additions to ActiveRecord models - define_index for creating indexes
# for models. If you want to interrogate the index objects created for the
# model, you can use the class-level accessor :sphinx_indexes.
#
module ThinkingSphinx::ActiveRecord
  def self.included(base)
    base.class_eval do
      extend ThinkingSphinx::ActiveRecord::ClassMethods
    end
  end
  
  module ClassMethods
    def set_sphinx_primary_key(attribute)
      @sphinx_primary_key_attribute = attribute
    end
    
    def primary_key_for_sphinx
      @sphinx_primary_key_attribute || primary_key
    end
    
    def sphinx_tailor_for(source)
      ThinkingSphinx::ActiveRecord::Tailor.new source
    end
    
    def find_for_sphinx(ids, options, index_options)
      find(:all,
        :joins      => options[:joins],
        :conditions => {primary_key_for_sphinx.to_sym => ids},
        :include    => (options[:include] || index_options[:include]),
        :select     => (options[:select]  || index_options[:select]),
        :order      => (options[:sql_order] || index_options[:sql_order])
      )
    end
    
    private
          
    def add_initial_sphinx_callbacks
      super
      
      before_validation :process_indexes
      before_destroy    :process_indexes
    end
    
    def add_standard_sphinx_callbacks
      super
      
      after_destroy :toggle_deleted
      
      include ThinkingSphinx::ActiveRecord::AttributeUpdates
    end
    
    def add_delta_sphinx_callbacks
      super
      
      before_save   :toggle_delta
      after_commit  :index_delta
    end
    
    def absolute_superclass
      ::ActiveRecord::Base
    end
    
    def sphinx_adapter_type
      case connection.class.name
      when "ActiveRecord::ConnectionAdapters::MysqlAdapter",
           "ActiveRecord::ConnectionAdapters::MysqlplusAdapter"
        :mysql
      when "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
        :postgresql
      when "ActiveRecord::ConnectionAdapters::JdbcAdapter"
        if model.connection.config[:adapter] == "jdbcmysql"
          :mysql
        elsif model.connection.config[:adapter] == "jdbcpostgresql"
          :postgresql
        else
          model.connection.config[:adapter].to_sym
        end
      else
        model.connection.class.name
      end
    end
  end
  
  # Returns the unique integer id for the object. This method uses the
  # attribute hash to get around ActiveRecord always mapping the #id method
  # to whatever the real primary key is (which may be a unique string hash).
  # 
  # @return [Integer] Unique record id for the purposes of Sphinx.
  # 
  def primary_key_for_sphinx
    @primary_key_for_sphinx ||= read_attribute(self.class.primary_key_for_sphinx)
  end

  private
  
  def process_indexes
    self.class.process_indexes
  end
end

ActiveRecord::Base.class_eval do
  include ThinkingSphinx::Base
  include ThinkingSphinx::ActiveRecord
end

ActiveRecord::Associations::HasManyAssociation.class_eval do
  include ThinkingSphinx::ActiveRecord::HasManyAssociation
end

ActiveRecord::Associations::HasManyThroughAssociation.class_eval do
  include ThinkingSphinx::ActiveRecord::HasManyAssociation
end
