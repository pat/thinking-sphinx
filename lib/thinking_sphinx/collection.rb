module ThinkingSphinx
  class Collection < ::Array
    attr_reader :total_entries, :total_pages, :current_page
    
    def initialize(page, per_page, entries, total_entries)
      @current_page, @per_page, @total_entries = page, per_page, total_entries
      
      @total_pages = (@total_entries / @per_page.to_f).ceil
    end
    
    def previous_page
      current_page > 1 ? (current_page - 1) : nil
    end
    
    def next_page
      current_page < total_pages ? (current_page + 1): nil
    end
    
    def offset
      (current_page - 1) * @per_page
    end
  end
end