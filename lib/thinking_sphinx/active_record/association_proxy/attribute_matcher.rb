class ThinkingSphinx::ActiveRecord::AssociationProxy::AttributeMatcher
    def initialize(attribute, foreign_key)
      @attribute, @foreign_key = attribute, foreign_key.to_s
    end

    def matches?
      return false if many?

      column_name_matches? || attribute_name_matches? || multi_singular_match?
    end

    private

    attr_reader :attribute, :foreign_key

    delegate :name, :multi?, :to => :attribute

    def attribute_name_matches?
      name == foreign_key
    end

    def column_name_matches?
      column.__name.to_s == foreign_key
    end

    def column
      attribute.respond_to?(:columns) ? attribute.columns.first :
        attribute.column
    end

    def many?
      attribute.respond_to?(:columns) && attribute.columns.many?
    end

    def multi_singular_match?
      multi? && name.singularize == foreign_key
    end
  end
