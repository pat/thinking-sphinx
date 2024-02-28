# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Updates to records in real-time indices', :live => true do
  it "handles fields with unicode nulls" do
    product = Product.create! :name => "Widget \u0000"

    expect(Product.search.first).to eq(product)
  end unless ENV['DATABASE'] == 'postgresql'

  it "handles attributes for sortable fields accordingly" do
    product = Product.create! :name => 'Red Fish'
    product.update :name => 'Blue Fish'

    expect(Product.search('blue fish', :indices => ['product_core']).to_a).
      to eq([product])
  end

  it "handles inserts and updates for namespaced models" do
    person = Admin::Person.create :name => 'Death'

    expect(Admin::Person.search('Death').to_a).to eq([person])

    person.update :name => 'Mort'

    expect(Admin::Person.search('Death').to_a).to be_empty
    expect(Admin::Person.search('Mort').to_a).to eq([person])
  end

  it "can use direct interface for upserting records" do
    Admin::Person.connection.execute <<~SQL
      INSERT INTO admin_people (name, created_at, updated_at)
      VALUES ('Pat', now(), now());
    SQL

    expect(Admin::Person.search('Pat').to_a).to be_empty

    instance = Admin::Person.find_by(:name => 'Pat')
    ThinkingSphinx::Processor.new(instance: instance).upsert

    expect(Admin::Person.search('Pat').to_a).to eq([instance])

    Admin::Person.connection.execute <<~SQL
      UPDATE admin_people SET name = 'Patrick' WHERE name = 'Pat';
    SQL

    expect(Admin::Person.search('Patrick').to_a).to be_empty

    instance.reload
    ThinkingSphinx::Processor.new(model: Admin::Person, id: instance.id).upsert

    expect(Admin::Person.search('Patrick').to_a).to eq([instance])
  end

  it "can use direct interface for processing records outside scope" do
    Article.connection.execute <<~SQL
      INSERT INTO articles (title, published, created_at, updated_at)
      VALUES ('Nice Title', TRUE, now(), now());
    SQL

    article  = Article.last

    ThinkingSphinx::Processor.new(model: article.class, id: article.id).stage

    expect(ThinkingSphinx.search('Nice', :indices => ["published_articles_core"])).to include(article)

    Article.connection.execute <<~SQL
      UPDATE articles SET published = FALSE WHERE title = 'Nice Title';
    SQL
    ThinkingSphinx::Processor.new(model: article.class, id: article.id).stage

    expect(ThinkingSphinx.search('Nice', :indices => ["published_articles_core"])).to be_empty
  end

  it "can use direct interface for processing deleted records" do
    Article.connection.execute <<~SQL
      INSERT INTO articles (title, published, created_at, updated_at)
      VALUES ('Nice Title', TRUE, now(), now());
    SQL

    article  = Article.last
    ThinkingSphinx::Processor.new(:instance => article).stage

    expect(ThinkingSphinx.search('Nice', :indices => ["published_articles_core"])).to include(article)

    Article.connection.execute <<~SQL
      DELETE FROM articles where title = 'Nice Title';
    SQL

    ThinkingSphinx::Processor.new(:instance => article).stage

    expect(ThinkingSphinx.search('Nice', :indices => ["published_articles_core"])).to be_empty
  end

  it "stages records in real-time index with alternate ids" do
    Album.connection.execute <<~SQL
      INSERT INTO albums (id, name, artist, integer_id)
      VALUES ('#{("a".."z").to_a.sample}', 'Sing to the Moon', 'Laura Mvula', #{rand(10000)});
    SQL

    album  = Album.last
    ThinkingSphinx::Processor.new(:model => Album, id: album.integer_id).stage

    expect(ThinkingSphinx.search('Laura', :indices => ["album_real_core"])).to include(album)

    Article.connection.execute <<~SQL
      DELETE FROM albums where id = '#{album.id}';
    SQL

    ThinkingSphinx::Processor.new(:instance => album).stage

    expect(ThinkingSphinx.search('Laura', :indices => ["album_real_core"])).to be_empty
  end
end
