class ThinkingSphinx::ActiveRecord::FilteredReflection <
  ActiveRecord::Reflection::AssociationReflection

  class Options
    attr_reader :reflection, :class_name, :options

    delegate :foreign_type, :active_record, :to => :reflection

    def initialize(reflection, class_name)
      @reflection, @class_name = reflection, class_name
      @options = reflection.options.clone
    end

    def filtered
      options.delete :polymorphic
      options[:class_name]    = class_name
      options[:foreign_key] ||= "#{reflection.name}_id"

      case options[:conditions]
      when nil
        options[:conditions] = condition
      when Array
        options[:conditions] << condition
      when Hash
        options[:conditions].merge!(reflection.foreign_type => options[:class_name])
      else
        options[:conditions] << " AND #{condition}"
      end

      options
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
    options = Options.new(reflection, class_name).filtered

    new reflection.macro, name, options, reflection.active_record
  end
end
