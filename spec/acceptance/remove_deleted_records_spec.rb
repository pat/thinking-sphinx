require 'acceptance/spec_helper'

describe 'Hiding deleted records from search results', :live => true do
  it "does not return deleted records" do
    pancakes = Article.create! :title => 'Pancakes'
    index

    expect(Article.search('pancakes')).not_to be_empty
    pancakes.destroy

    expect(Article.search('pancakes')).to be_empty
  end

  it "will catch stale records deleted without callbacks being fired" do
    pancakes = Article.create! :title => 'Pancakes'
    index

    expect(Article.search('pancakes')).not_to be_empty
    Article.connection.execute "DELETE FROM articles WHERE id = #{pancakes.id}"

    expect(Article.search('pancakes')).to be_empty
  end

  it "removes records from real-time index results" do
    product = Product.create! :name => 'Shiny'

    expect(Product.search('Shiny', :indices => ['product_core']).to_a).
      to eq([product])

    product.destroy

    expect(Product.search_for_ids('Shiny', :indices => ['product_core'])).
      to be_empty
  end

  it "does not remove real-time results when callbacks are disabled" do
    original = ThinkingSphinx::Configuration.instance.
      settings['real_time_callbacks']
    product = Product.create! :name => 'Shiny'
    expect(Product.search('Shiny', :indices => ['product_core']).to_a).
      to eq([product])

    ThinkingSphinx::Configuration.instance.
      settings['real_time_callbacks'] = false

    product.destroy
    expect(Product.search_for_ids('Shiny', :indices => ['product_core'])).
      not_to be_empty

    ThinkingSphinx::Configuration.instance.
      settings['real_time_callbacks'] = original
  end

  it "deletes STI child classes from parent indices" do
    duck = Bird.create :name => 'Duck'
    index
    duck.destroy

    expect(Bird.search_for_ids('duck')).to be_empty
  end
end
