require 'spec_helper'

describe 'specifying joins' do
  it "renders the SQL with the join" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    index.definition_block = Proc.new {
      indexes title
      join user
    }
    index.render
    index.sources.first.sql_query.should match(/LEFT OUTER JOIN .users./)
  end

  it "handles deep joins" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    index.definition_block = Proc.new {
      indexes title
      join user.articles
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/LEFT OUTER JOIN .users./)
    query.should match(/LEFT OUTER JOIN .articles./)
  end
end
