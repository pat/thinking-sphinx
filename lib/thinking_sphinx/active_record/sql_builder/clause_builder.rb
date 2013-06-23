module ThinkingSphinx
  module ActiveRecord
    class SQLBuilder::ClauseBuilder
      def initialize(first_element)
        @first_element = first_element
      end

      def compose(*additions)
        additions.each &method(:add_clause)
        self
      end

      def add_clause(clause)
        self.clauses += Array(clause)
      end

      def separated(by = ', ')
        clauses.flatten.compact.join(by)
      end

      protected
      attr_accessor :clauses
      def clauses
        @clauses ||= [@first_element]
      end
    end
  end
end
