class ThinkingSphinx::Context
  attr_reader :indexed_models
  
  def initialize
    @indexed_models = []
  end
  
  def prepare
    load_models
  end
  
  def define_indexes
    indexed_models.each { |model|
      model.constantize.define_indexes
    }
  end
  
  def add_indexed_model(model)
    model = model.name if model.is_a?(Class)
    
    indexed_models << model
    indexed_models.uniq!
    indexed_models.sort!
  end
  
  def superclass_indexed_models
    klasses = indexed_models.collect { |name| name.constantize }
    klasses.reject { |klass|
      klass.superclass.ancestors.any? { |ancestor| klasses.include?(ancestor) }
    }.collect { |klass| klass.name }
  end
  
  private
  
  # Make sure all models are loaded - without reloading any that
  # ActiveRecord::Base is already aware of (otherwise we start to hit some
  # messy dependencies issues).
  #
  def load_models
    return if defined?(Rails) &&
      Rails::VERSION::STRING.to_f > 2.1 &&
      Rails.configuration.cache_classes
    
    ThinkingSphinx::Configuration.instance.model_directories.each do |base|
      Dir["#{base}**/*.rb"].each do |file|
        model_name = file.gsub(/^#{base}([\w_\/\\]+)\.rb/, '\1')
      
        next if model_name.nil?
        next if ::ActiveRecord::Base.send(:subclasses).detect { |model|
          model.name == model_name
        }
      
        begin
          model_name.camelize.constantize
        rescue LoadError
          model_name.gsub!(/.*[\/\\]/, '').nil? ? next : retry
        rescue NameError
          next
        rescue StandardError
          STDERR.puts "Warning: Error loading #{file}"
        end
      end
    end
  end
end
