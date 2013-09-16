module ThinkingSphinx
  module ActiveRecord
    class SQLBuilder::ClauseBuilder
      def initialize(first_element)
        @clauses = [first_element]
      end

      def compose(*additions)
        additions.each &method(:add_clause)

        self
      end

      def add_clause(clause)
        @clauses += Array(clause)
      end

      def separated(by = ', ')
        clauses.flatten.compact.join(by)
      end

      private

      attr_reader :clauses
    end
  end
end
