class ThinkingSphinx::ActiveRecord::Polymorpher
  def initialize(source, column, class_names)
    @source, @column, @class_names = source, column, class_names
  end

  def morph!
    keys = class_names.collect { |class_name|
      name = "#{column.__name}_#{class_name.downcase}".to_sym

      klass.reflections[name] ||= ActiveRecord::Reflection::
        AssociationReflection.new(reflection.macro, name,
        casted_options(class_name), reflection.active_record)

      name
    }

    stacks = keys.collect { |key| column.__stack + [key] }

    (source.fields + source.attributes).each do |property|
      property.rebase column.__path, :to => stacks
    end
  end

  private

  attr_reader :source, :column, :class_names

  def casted_options(class_name)
    options = reflection.options.clone
    options[:polymorphic]   = nil
    options[:class_name]    = class_name
    options[:foreign_key] ||= "#{reflection.name}_id"

    case options[:conditions]
    when nil
      options[:conditions] = "::ts_join_alias::.#{quoted_foreign_type} = '#{class_name}'"
    when Array
      options[:conditions] << "::ts_join_alias::.#{quoted_foreign_type} = '#{class_name}'"
    when Hash
      options[:conditions].merge!(reflection.foreign_type => class_name)
    else
      options[:conditions] << " AND ::ts_join_alias::.#{quoted_foreign_type} = '#{class_name}'"
    end

    options
  end

  def quoted_foreign_type
    klass.connection.quote_column_name reflection.foreign_type
  end

  def reflection
    @reflection ||= klass.reflections[column.__name]
  end

  def klass
    @klass ||= column.__stack.inject(source.model) { |parent, key|
      parent.reflections[key].klass
    }
  end
end
