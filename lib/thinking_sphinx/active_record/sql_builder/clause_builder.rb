module ThinkingSphinx
  module ActiveRecord
    class SQLBuilder::ClauseBuilder
      def initialize(first_element)
        @first_element = first_element
      end

      def compose(*additions)
        additions.each &method(:add_clause)

        comma_separated
      end

      def add_clause(clause)
        self.clauses += clause
      end

      protected
      attr_accessor :clauses
      def clauses
        @clauses ||= [@first_element]
      end

      def comma_separated
        clauses.flatten.compact.join(', ')
      end
    end
  end
end
