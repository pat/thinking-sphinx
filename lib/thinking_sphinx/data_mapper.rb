module ThinkingSphinx::DataMapper
  def self.included(base)
    base.class_eval do
      extend ThinkingSphinx::DataMapper::ClassMethods
    end
  end
  
  module ClassMethods
    def sphinx_tailor_for(source)
      ThinkingSphinx::DataMapper::Tailor.new source
    end
    
    private
          
    def add_initial_sphinx_callbacks
      super
      
      # before_validation :process_indexes
      # before_destroy    :process_indexes
    end
    
    def add_standard_sphinx_callbacks
      super
      
      # after_destroy :toggle_deleted
      
      # include ThinkingSphinx::ActiveRecord::AttributeUpdates
    end
    
    def add_delta_sphinx_callbacks
      super
      
      # before_save   :toggle_delta
      # after_commit  :index_delta
    end
    
    def sphinx_adapter_type
      case repository.adapter.class.name
      when "DataMapper::ConnectionAdapters::MysqlAdapter",
           "DataMapper::ConnectionAdapters::MysqlplusAdapter"
        :mysql
      when "DataMapper::ConnectionAdapters::PostgreSQLAdapter"
        :postgresql
      else
        model.repository.adapter.class.name
      end
    end
  end
  
  def primary_key_for_sphinx
    id
  end
end

require 'thinking_sphinx/data_mapper/tailor'
