class Book < ActiveRecord::Base
  include ThinkingSphinx::Scopes

  has_and_belongs_to_many :genres

  sphinx_scope(:by_query) { |query| query }
  sphinx_scope(:by_year) do |year|
    {:with => {:year => year}}
  end
  sphinx_scope(:by_query_and_year) do |query, year|
    [query, {:with => {:year =>year}}]
  end
end
