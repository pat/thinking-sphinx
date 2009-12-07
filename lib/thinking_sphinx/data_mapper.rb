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
      all(
        primary_key_for_sphinx.to_sym => ids,
        :order => (options[:sql_order] || index_options[:sql_order])
      )
    end
    
    private
          
    def add_initial_sphinx_callbacks
      super

      before :save,    :process_indexes # is before_validation in AR
      before :destroy, :process_indexes
    end
    
    def add_standard_sphinx_callbacks
      super
      
      after :destroy, :toggle_deleted
    end
    
    def add_delta_sphinx_callbacks
      super
      
      before :save, :toggle_delta
      after  :save, :index_delta
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
  
  def new_record_for_sphinx?
    new?
  end
end

require 'thinking_sphinx/data_mapper/tailor'
