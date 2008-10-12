module ThinkingSphinx
  class MysqlAdapter < AbstractAdapter
    class << self
      def setup
        # Does MySQL actually need to do anything?
      end
    end
  end
end