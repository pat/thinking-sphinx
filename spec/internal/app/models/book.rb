class Book < ActiveRecord::Base
  include ThinkingSphinx::Scopes

  sphinx_scope(:by_year) do |year|
    {:with => {:year => year}}
  end
end
