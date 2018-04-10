# frozen_string_literal: true

class ThinkingSphinx::RealTime::Interpreter <
  ::ThinkingSphinx::Core::Interpreter

  def has(*columns)
    options = columns.extract_options!
    @index.attributes += columns.collect { |column|
      ::ThinkingSphinx::RealTime::Attribute.new column, options
    }
  end

  def indexes(*columns)
    options = columns.extract_options!
    @index.fields += columns.collect { |column|
      ::ThinkingSphinx::RealTime::Field.new column, options
    }

    append_sortable_attributes columns, options if options[:sortable]
  end

  def scope(&block)
    @index.scope = block
  end

  def set_property(properties)
    properties.each do |key, value|
      @index.send("#{key}=", value) if @index.class.settings.include?(key)
      @index.options[key] = value   if search_option?(key)
    end
  end

  def where(condition)
    @index.conditions << condition
  end

  private

  def append_sortable_attributes(columns, options)
    options = options.except(:sortable).merge(:type => :string)

    @index.attributes += columns.collect { |column|
      aliased_name   = options[:as]
      aliased_name ||= column.__name.to_sym if column.respond_to?(:__name)
      aliased_name ||= column

      options[:as] = "#{aliased_name}_sort".to_sym

      ::ThinkingSphinx::RealTime::Attribute.new column, options
    }
  end
end
