class ThinkingSphinx::Masks::PaginationMask
  def initialize(search)
    @search = search
  end

  def current_page
    search.options[:page] = 1 if search.options[:page].blank?
    search.options[:page].to_i
  end

  def first_page?
    current_page == 1
  end

  def last_page?
    next_page.nil?
  end

  def next_page
    current_page >= total_pages ? nil : current_page + 1
  end

  def next_page?
    !next_page.nil?
  end

  def page(number)
    search.options[:page] = number
    search
  end

  def per(limit)
    search.options[:limit] = limit
    search
  end

  def previous_page
    current_page == 1 ? nil : current_page - 1
  end

  def total_entries
    search.meta['total_found'].to_i
  end

  alias_method :total_count, :total_entries
  alias_method :count,       :total_entries

  def total_pages
    return 0 if search.meta['total'].nil?

    @total_pages ||= (search.meta['total'].to_i / search.per_page.to_f).ceil
  end

  alias_method :page_count, :total_pages
  alias_method :num_pages,  :total_pages

  private

  attr_reader :search
end
