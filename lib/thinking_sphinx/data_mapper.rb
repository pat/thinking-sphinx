module ThinkingSphinx::DataMapper
  def self.included(base)
    base.class_eval do
      extend ThinkingSphinx::DataMapper::ClassMethods
    end
  end
  
  module ClassMethods
    def primary_key_for_sphinx
      :id
    end
    
    def sphinx_tailor_for(source)
      ThinkingSphinx::DataMapper::Tailor.new source
    end
    
    def find_for_sphinx(ids, options, index_options)
      all(primary_key_for_sphinx.to_sym => ids)
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
      when "DataMapper::Adapters::MysqlAdapter"
        :mysql
      when "DataMapper::Adapters::PostgresAdapter"
        :postgresql
      else
        repository.adapter.class.name
      end
    end
  end
  
  def primary_key_for_sphinx
    id
  end
end

require 'thinking_sphinx/data_mapper/tailor'
