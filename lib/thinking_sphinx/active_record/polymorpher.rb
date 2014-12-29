class ThinkingSphinx::ActiveRecord::Polymorpher
  def initialize(source, column, class_names)
    @source, @column, @class_names = source, column, class_names
  end

  def morph!
    append_reflections
    morph_properties
  end

  private

  attr_reader :source, :column, :class_names

  def append_reflections
    mappings.each do |class_name, name|
      next if klass.reflect_on_association(name)

      reflection = clone_with name, class_name
      if ActiveRecord::Reflection.respond_to?(:add_reflection)
        ActiveRecord::Reflection.add_reflection klass, name, reflection
      else
        klass.reflections[name] = reflection
      end
    end
  end

  def clone_with(name, class_name)
    ThinkingSphinx::ActiveRecord::FilterReflection.call(
      reflection, name, class_name
    )
  end

  def mappings
    @mappings ||= class_names.inject({}) do |hash, class_name|
      hash[class_name] = "#{column.__name}_#{class_name.downcase}".to_sym
      hash
    end
  end

  def morphed_stacks
    @morphed_stacks ||= mappings.values.collect { |key|
      column.__stack + [key]
    }
  end

  def morph_properties
    (source.fields + source.attributes).each do |property|
      property.rebase column.__path, :to => morphed_stacks
    end
  end

  def reflection
    @reflection ||= klass.reflect_on_association column.__name
  end

  def klass
    @klass ||= column.__stack.inject(source.model) { |parent, key|
      parent.reflect_on_association(key).klass
    }
  end
end
