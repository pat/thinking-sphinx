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
end

describe 'separate queries for MVAs' do
  let(:index)  { ThinkingSphinx::ActiveRecord::Index.new(:article) }
  let(:count)  { ThinkingSphinx::Configuration.instance.indices.count }
  let(:source) { index.sources.first }

  it "generates an appropriate SQL query for an MVA attribute" do
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

  it "generates a SQL query with joins when appropriate for MVA attributes" do
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
end
