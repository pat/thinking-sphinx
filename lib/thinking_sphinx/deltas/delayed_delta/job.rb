module ThinkingSphinx
  module Deltas
    class Jobb < Delayed::Job
      def self.enqueue(object, priority = 0)
        super unless duplicates_exist(object)
      end

      private

      def self.duplicates_exist(object)
        count(
          :conditions => {
            :handler    => object.to_yaml,
            :locked_at  => nil
          }
        ) > 0
      end
    end
  end
end
