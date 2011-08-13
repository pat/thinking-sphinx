module ThinkingSphinx::ActiveRecord::Base
  def search(query = nil)
    ThinkingSphinx::Search.new query
  end
end
