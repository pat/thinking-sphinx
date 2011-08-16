class ThinkingSphinx::Context
  attr_reader :indexed_models

  def initialize(*models)
    @indexed_models = []
  end

  def prepare
    ThinkingSphinx::Configuration.instance.indexed_models.each do |model|
      add_indexed_model model
    end

    return unless indexed_models.empty?

    load_models
    add_indexed_models
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

  def add_indexed_models
    ActiveRecord::Base.descendants.each do |klass|
      add_indexed_model klass if klass.has_sphinx_indexes?
    end
  end

  # Make sure all models are loaded - without reloading any that
  # ActiveRecord::Base is already aware of (otherwise we start to hit some
  # messy dependencies issues).
  #
  def load_models
    ThinkingSphinx::Configuration.instance.model_directories.each do |base|
      Dir["#{base}**/*.rb"].each do |file|
        model_name = file.gsub(/^#{base}([\w_\/\\]+)\.rb/, '\1')

        next if model_name.nil?
        camelized_model = model_name.camelize
        next if ::ActiveRecord::Base.send(:descendants).detect { |model|
          model.name == camelized_model
        }

        begin
          camelized_model.constantize
        rescue LoadError
          model_name.gsub!(/.*[\/\\]/, '').nil? ? next : retry
        rescue NameError
          next
        rescue StandardError => err
          STDERR.puts "Warning: Error loading #{file}:"
          STDERR.puts err.message
          STDERR.puts err.backtrace.join("\n"), ''
        end
      end
    end
  end
end
