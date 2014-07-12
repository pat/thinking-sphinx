class ThinkingSphinx::ActiveRecord::FilteredReflection <
  ActiveRecord::Reflection::AssociationReflection

  class Filter
    attr_reader :reflection, :class_name

    delegate :foreign_type, :active_record, :to => :reflection

    def initialize(reflection, class_name)
      @reflection, @class_name = reflection, class_name
      @options = reflection.options.clone
    end

    def options
      @options.delete :polymorphic
      @options[:class_name]    = class_name
      @options[:foreign_key] ||= "#{reflection.name}_id"
      @options[:foreign_type]  = reflection.foreign_type

      if reflection.respond_to?(:scope)
        @options[:sphinx_internal_filtered] = true
        return @options
      end

      case @options[:conditions]
      when nil
        @options[:conditions] = condition
      when Array
        @options[:conditions] << condition
      when Hash
        @options[:conditions].merge!(reflection.foreign_type => @options[:class_name])
      else
        @options[:conditions] << " AND #{condition}"
      end

      @options
    end

    def scope
      if ::Joiner::Joins.instance_methods.include?(:join_association_class)
        return nil
      end

      lambda { |association|
        reflection = association.reflection
        where(
          association.parent.aliased_table_name.to_sym =>
          {reflection.foreign_type => reflection.class_name}
        )
      }
    end

    private

    def condition
      "::ts_join_alias::.#{quoted_foreign_type} = '#{class_name}'"
    end

    def quoted_foreign_type
      active_record.connection.quote_column_name foreign_type
    end
  end

  def self.clone_with_filter(reflection, name, class_name)
    filter = Filter.new(reflection, class_name)

    if reflection.respond_to?(:scope)
      new reflection.macro, name, filter.scope, filter.options,
        reflection.active_record
    else
      new reflection.macro, name, filter.options, reflection.active_record
    end
  end
end
