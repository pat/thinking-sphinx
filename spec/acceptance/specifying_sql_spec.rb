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

  it "handles has-many :through joins" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    index.definition_block = Proc.new {
      indexes tags.name
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/LEFT OUTER JOIN .taggings./)
    query.should match(/LEFT OUTER JOIN .tags./)
  end

  it "handles custom join SQL statements" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    index.definition_block = Proc.new {
      indexes title
      join "INNER JOIN foo ON foo.x = bar.y"
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/INNER JOIN foo ON foo.x = bar.y/)
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

  it "handles manual MVA declarations" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    index.definition_block = Proc.new {
      indexes title
      has "taggings.tag_ids", :as => :tag_ids, :type => :integer,
        :multi => true
    }
    index.render

    index.sources.first.sql_attr_multi.should == ['uint tag_ids from field']
  end

  it "provides the sanitize_sql helper within the index definition block" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    index.definition_block = Proc.new {
      indexes title
      where sanitize_sql(["title != ?", 'secret'])
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/WHERE .+title != 'secret'.+ GROUP BY/)
  end

  it "escapes new lines in SQL snippets" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    index.definition_block = Proc.new {
      indexes title
      has <<-SQL, as: :custom_attribute,  type: :integer
      ARRAY_AGG(
        CONCAT(
          something
        )
      )
      SQL
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/\\\n/)
  end

  it "joins each polymorphic relation" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:event)
    index.definition_block = Proc.new {
      indexes eventable.title, :as => :title
      polymorphs eventable, :to => %w(Article Book)
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/LEFT OUTER JOIN .articles. ON .articles.\..id. = .events.\..eventable_id. AND .events.\..eventable_type. = 'Article'/)
    query.should match(/LEFT OUTER JOIN .books. ON .books.\..id. = .events.\..eventable_id. AND .events.\..eventable_type. = 'Book'/)
    query.should match(/articles\..title., books\..title./)
  end

  it "concatenates references where that have column" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:event)
    index.definition_block = Proc.new {
      indexes eventable.title, :as => :title
      polymorphs eventable, :to => %w(Article User)
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/LEFT OUTER JOIN .articles. ON .articles.\..id. = .events.\..eventable_id. AND .events.\..eventable_type. = 'Article'/)
    query.should match(/LEFT OUTER JOIN .users. ON .users.\..id. = .events.\..eventable_id. AND .events.\..eventable_type. = 'User'/)
    query.should_not match(/articles\..title., users\..title./)
  end

  it "respects deeper associations through polymorphic joins" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:event)
    index.definition_block = Proc.new {
      indexes eventable.user.name, :as => :user_name
      polymorphs eventable, :to => %w(Article Book)
    }
    index.render

    query = index.sources.first.sql_query
    query.should match(/LEFT OUTER JOIN .articles. ON .articles.\..id. = .events.\..eventable_id. AND .events.\..eventable_type. = 'Article'/)
    query.should match(/LEFT OUTER JOIN .users. ON .users.\..id. = .articles.\..user_id./)
    query.should match(/users\..name./)
  end
end

describe 'separate queries for MVAs' do
  let(:index)  { ThinkingSphinx::ActiveRecord::Index.new(:article) }
  let(:count)  { ThinkingSphinx::Configuration.instance.indices.count }
  let(:source) { index.sources.first }

  it "generates an appropriate SQL query for an MVA" do
    index.definition_block = Proc.new {
      indexes title
      has taggings.tag_id, :as => :tag_ids, :source => :query
    }
    index.render

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/tag_ids/]
    }
    declaration, query = attribute.split(/;\s+/)

    declaration.should == 'uint tag_ids from query'
    query.should match(/^SELECT .taggings.\..article_id. \* #{count} \+ #{source.offset} AS .id., .taggings.\..tag_id. AS .tag_ids. FROM .taggings.\s?$/)
  end

  it "generates a SQL query with joins when appropriate for MVAs" do
    index.definition_block = Proc.new {
      indexes title
      has taggings.tag.id, :as => :tag_ids, :source => :query
    }
    index.render

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/tag_ids/]
    }
    declaration, query = attribute.split(/;\s+/)

    declaration.should == 'uint tag_ids from query'
    query.should match(/^SELECT .taggings.\..article_id. \* #{count} \+ #{source.offset} AS .id., .tags.\..id. AS .tag_ids. FROM .taggings. INNER JOIN .tags. ON .tags.\..id. = .taggings.\..tag_id.\s?$/)
  end

  it "respects has_many :through joins for MVA queries" do
    index.definition_block = Proc.new {
      indexes title
      has tags.id, :as => :tag_ids, :source => :query
    }
    index.render

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/tag_ids/]
    }
    declaration, query = attribute.split(/;\s+/)

    declaration.should == 'uint tag_ids from query'
    query.should match(/^SELECT .taggings.\..article_id. \* #{count} \+ #{source.offset} AS .id., .tags.\..id. AS .tag_ids. FROM .taggings. INNER JOIN .tags. ON .tags.\..id. = .taggings.\..tag_id.\s?$/)
  end

  it "can handle multiple joins for MVA queries" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:user)
    index.definition_block = Proc.new {
      indexes name
      has articles.tags.id, :as => :tag_ids, :source => :query
    }
    index.render
    source = index.sources.first

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/tag_ids/]
    }
    declaration, query = attribute.split(/;\s+/)

    declaration.should == 'uint tag_ids from query'
    query.should match(/^SELECT .articles.\..user_id. \* #{count} \+ #{source.offset} AS .id., .tags.\..id. AS .tag_ids. FROM .articles. INNER JOIN .taggings. ON .taggings.\..article_id. = .articles.\..id. INNER JOIN .tags. ON .tags.\..id. = .taggings.\..tag_id.\s?$/)
  end

  it "can handle HABTM joins for MVA queries" do
    pending "Efficient HABTM queries are tricky."
    # We don't really have any need for other tables, but that doesn't lend
    # itself nicely to Thinking Sphinx's DSL, nor ARel SQL generation. This is
    # a low priority - manual SQL queries for this situation may work better.

    index = ThinkingSphinx::ActiveRecord::Index.new(:book)
    index.definition_block = Proc.new {
      indexes title
      has genres.id, :as => :genre_ids, :source => :query
    }
    index.render
    source = index.sources.first

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/genre_ids/]
    }
    declaration, query = attribute.split(/;\s+/)

    declaration.should == 'uint genre_ids from query'
    query.should match(/^SELECT .books_genres.\..book_id. \* #{count} \+ #{source.offset} AS .id., .genres.\..id. AS .genre_ids. FROM .books_genres. INNER JOIN .genres. ON .genres.\..id. = .books_genres.\..genre_id.\s?$/)
  end

  it "generates an appropriate range SQL queries for an MVA" do
    index.definition_block = Proc.new {
      indexes title
      has taggings.tag_id, :as => :tag_ids, :source => :ranged_query
    }
    index.render

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/tag_ids/]
    }
    declaration, query, range = attribute.split(/;\s+/)

    declaration.should == 'uint tag_ids from ranged-query'
    query.should match(/^SELECT .taggings.\..article_id. \* #{count} \+ #{source.offset} AS .id., .taggings.\..tag_id. AS .tag_ids. FROM .taggings. \s?WHERE \(.taggings.\..article_id. BETWEEN \$start AND \$end\)$/)
    range.should match(/^SELECT MIN\(.taggings.\..article_id.\), MAX\(.taggings.\..article_id.\) FROM .taggings.\s?$/)
  end

  it "generates a SQL query with joins when appropriate for MVAs" do
    index.definition_block = Proc.new {
      indexes title
      has taggings.tag.id, :as => :tag_ids, :source => :ranged_query
    }
    index.render

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/tag_ids/]
    }
    declaration, query, range = attribute.split(/;\s+/)

    declaration.should == 'uint tag_ids from ranged-query'
    query.should match(/^SELECT .taggings.\..article_id. \* #{count} \+ #{source.offset} AS .id., .tags.\..id. AS .tag_ids. FROM .taggings. INNER JOIN .tags. ON .tags.\..id. = .taggings.\..tag_id. \s?WHERE \(.taggings.\..article_id. BETWEEN \$start AND \$end\)$/)
    range.should match(/^SELECT MIN\(.taggings.\..article_id.\), MAX\(.taggings.\..article_id.\) FROM .taggings.\s?$/)
  end

  it "respects custom SQL snippets as the query value" do
    index.definition_block = Proc.new {
      indexes title
      has 'My Custom SQL Query', :as => :tag_ids, :source => :query,
        :type => :integer, :multi => true
    }
    index.render

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/tag_ids/]
    }
    declaration, query = attribute.split(/;\s+/)

    declaration.should == 'uint tag_ids from query'
    query.should == 'My Custom SQL Query'
  end

  it "respects custom SQL snippets as the ranged query value" do
    index.definition_block = Proc.new {
      indexes title
      has 'My Custom SQL Query; And a Range', :as => :tag_ids,
        :source => :ranged_query, :type => :integer, :multi => true
    }
    index.render

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/tag_ids/]
    }
    declaration, query, range = attribute.split(/;\s+/)

    declaration.should == 'uint tag_ids from ranged-query'
    query.should == 'My Custom SQL Query'
    range.should == 'And a Range'
  end

  it "escapes new lines in custom SQL snippets" do
    index.definition_block = Proc.new {
      indexes title
      has <<-SQL, :as => :tag_ids, :source => :query, :type => :integer, :multi => true
My Custom
SQL Query
      SQL
    }
    index.render

    attribute = source.sql_attr_multi.detect { |attribute|
      attribute[/tag_ids/]
    }
    declaration, query = attribute.split(/;\s+/)

    declaration.should == 'uint tag_ids from query'
    query.should == "My Custom\\\nSQL Query"
  end
end

describe 'separate queries for field' do
  let(:index)  { ThinkingSphinx::ActiveRecord::Index.new(:article) }
  let(:count)  { ThinkingSphinx::Configuration.instance.indices.count }
  let(:source) { index.sources.first }

  it "generates a SQL query with joins when appropriate for MVF" do
    index.definition_block = Proc.new {
      indexes taggings.tag.name, :as => :tags, :source => :query
    }
    index.render

    field = source.sql_joined_field.detect { |field| field[/tags/] }
    declaration, query = field.split(/;\s+/)

    declaration.should == 'tags from query'
    query.should match(/^SELECT .taggings.\..article_id. \* #{count} \+ #{source.offset} AS .id., .tags.\..name. AS .tags. FROM .taggings. INNER JOIN .tags. ON .tags.\..id. = .taggings.\..tag_id.\s? ORDER BY .taggings.\..article_id. ASC\s?$/)
  end

  it "respects has_many :through joins for MVF queries" do
    index.definition_block = Proc.new {
      indexes tags.name, :as => :tags, :source => :query
    }
    index.render

    field = source.sql_joined_field.detect { |field| field[/tags/] }
    declaration, query = field.split(/;\s+/)

    declaration.should == 'tags from query'
    query.should match(/^SELECT .taggings.\..article_id. \* #{count} \+ #{source.offset} AS .id., .tags.\..name. AS .tags. FROM .taggings. INNER JOIN .tags. ON .tags.\..id. = .taggings.\..tag_id.\s? ORDER BY .taggings.\..article_id. ASC\s?$/)
  end

  it "can handle multiple joins for MVF queries" do
    index = ThinkingSphinx::ActiveRecord::Index.new(:user)
    index.definition_block = Proc.new {
      indexes articles.tags.name, :as => :tags, :source => :query
    }
    index.render
    source = index.sources.first

    field = source.sql_joined_field.detect { |field| field[/tags/] }
    declaration, query = field.split(/;\s+/)

    declaration.should == 'tags from query'
    query.should match(/^SELECT .articles.\..user_id. \* #{count} \+ #{source.offset} AS .id., .tags.\..name. AS .tags. FROM .articles. INNER JOIN .taggings. ON .taggings.\..article_id. = .articles.\..id. INNER JOIN .tags. ON .tags.\..id. = .taggings.\..tag_id.\s? ORDER BY .articles.\..user_id. ASC\s?$/)
  end

  it "generates a SQL query with joins when appropriate for MVFs" do
    index.definition_block = Proc.new {
      indexes taggings.tag.name, :as => :tags, :source => :ranged_query
    }
    index.render

    field = source.sql_joined_field.detect { |field| field[/tags/] }
    declaration, query, range = field.split(/;\s+/)

    declaration.should == 'tags from ranged-query'
    query.should match(/^SELECT .taggings.\..article_id. \* #{count} \+ #{source.offset} AS .id., .tags.\..name. AS .tags. FROM .taggings. INNER JOIN .tags. ON .tags.\..id. = .taggings.\..tag_id. \s?WHERE \(.taggings.\..article_id. BETWEEN \$start AND \$end\)\s? ORDER BY .taggings.\..article_id. ASC$/)
    range.should match(/^SELECT MIN\(.taggings.\..article_id.\), MAX\(.taggings.\..article_id.\) FROM .taggings.\s?$/)
  end

  it "respects custom SQL snippets as the query value" do
    index.definition_block = Proc.new {
      indexes 'My Custom SQL Query', :as => :tags, :source => :query
    }
    index.render

    field = source.sql_joined_field.detect { |field| field[/tags/] }
    declaration, query = field.split(/;\s+/)

    declaration.should == 'tags from query'
    query.should == 'My Custom SQL Query'
  end

  it "respects custom SQL snippets as the ranged query value" do
    index.definition_block = Proc.new {
      indexes 'My Custom SQL Query; And a Range', :as => :tags,
        :source => :ranged_query
    }
    index.render

    field = source.sql_joined_field.detect { |field| field[/tags/] }
    declaration, query, range = field.split(/;\s+/)

    declaration.should == 'tags from ranged-query'
    query.should == 'My Custom SQL Query'
    range.should == 'And a Range'
  end

  it "escapes new lines in custom SQL snippets" do
    index.definition_block = Proc.new {
      indexes <<-SQL, :as => :tags, :source => :query
My Custom
SQL Query
      SQL
    }
    index.render

    field = source.sql_joined_field.detect { |field| field[/tags/] }
    declaration, query = field.split(/;\s+/)

    declaration.should == 'tags from query'
    query.should == "My Custom\\\nSQL Query"
  end
end
