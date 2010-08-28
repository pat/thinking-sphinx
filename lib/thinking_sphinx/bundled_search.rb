module ThinkingSphinx
  class BundledSearch
    attr_reader :client
    
    def initialize
      @searches = []
    end
    
    def search(*args)
      @searches << ThinkingSphinx.search(*args)
      @searches.last.append_to client
    end
    
    def searches
      populate
      @searches
    end
    
    private
    
    def client
      @client ||= ThinkingSphinx::Configuration.instance.client
    end
    
    def populated?
      @populated
    end
    
    def populate
      return if populated?
      
      @populated = true
      
      client.run.each_with_index do |results, index|
        searches[index].populate_from_queue results
      end
    end
  end
end
