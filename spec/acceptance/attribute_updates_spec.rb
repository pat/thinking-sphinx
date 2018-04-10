# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Update attributes automatically where possible', :live => true do
  it "updates boolean values" do
    article = Article.create :title => 'Pancakes', :published => false
    index

    expect(Article.search('pancakes', :with => {:published => true})).to be_empty

    article.published = true
    article.save

    expect(Article.search('pancakes', :with => {:published => true}).to_a)
      .to eq([article])
  end
end
