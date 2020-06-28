# frozen_string_literal: true

class Book < ActiveRecord::Base
  include ThinkingSphinx::Scopes

  has_and_belongs_to_many :genres

  ThinkingSphinx::Callbacks.append(self, :behaviours => [:sql, :deltas])

  sphinx_scope(:by_query) { |query| query }
  sphinx_scope(:by_year) do |year|
    {:with => {:year => year}}
  end
  sphinx_scope(:by_query_and_year) do |query, year|
    [query, {:with => {:year =>year}}]
  end
  sphinx_scope(:ordered) { {:order => 'year DESC'} }
end
