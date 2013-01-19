module ThinkingSphinx
  class BundledSearch
    def initialize
      @searches = []
    end

    def search(*args)
      @searches << ThinkingSphinx.search(*args)
    end

    def search_for_ids(*args)
      @searches << ThinkingSphinx.search_for_ids(*args)
    end

    def searches
      populate
      @searches
    end

    private

    def populated?
      @populated
    end

    def populate
      return if populated?

      @populated = true

      ThinkingSphinx::Connection.take do |client|
        @searches.each { |search| search.append_to client }

        client.run.each_with_index do |results, index|
          searches[index].populate_from_queue results
        end
      end
    end
  end
end
