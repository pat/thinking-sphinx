require 'acceptance/spec_helper'

describe 'specifying SQL for index definitions' do
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

  it "handles GROUP BY clauses" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    index.definition_block = Proc.new {
      indexes title
      group_by 'lat'
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/GROUP BY .articles.\..id., .articles.\..title., .articles.\..id., lat/)
  end

  it "handles WHERE clauses" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    index.definition_block = Proc.new {
      indexes title
      where "title != 'secret'"
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/WHERE .+title != 'secret'.+ GROUP BY/)
  end
end
