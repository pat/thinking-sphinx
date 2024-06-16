# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Grouping search results by attributes', :live => true do
  it "groups by the provided attribute" do
    snuff  = Book.create! :title => 'Snuff',          :publishing_year => 2011
    earth  = Book.create! :title => 'The Long Earth', :publishing_year => 2012
    dodger = Book.create! :title => 'Dodger',         :publishing_year => 2012

    index

    expect(Book.search(:group_by => :publishing_year).to_a).to eq([snuff, earth])
  end

  it "allows sorting within the group" do
    snuff  = Book.create! :title => 'Snuff',          :publishing_year => 2011
    earth  = Book.create! :title => 'The Long Earth', :publishing_year => 2012
    dodger = Book.create! :title => 'Dodger',         :publishing_year => 2012

    index

    expect(Book.search(:group_by => :publishing_year, :order_group_by => 'title ASC').to_a).
      to eq([snuff, dodger])
  end

  it "allows enumerating by count" do
    snuff  = Book.create! :title => 'Snuff',          :publishing_year => 2011
    earth  = Book.create! :title => 'The Long Earth', :publishing_year => 2012
    dodger = Book.create! :title => 'Dodger',         :publishing_year => 2012

    index

    expectations = [[snuff, 1], [earth, 2]]

    Book.search(:group_by => :publishing_year).each_with_count do |book, count|
      expectation = expectations.shift

      expect(book).to  eq(expectation.first)
      expect(count).to eq(expectation.last)
    end
  end

  it "allows enumerating by group" do
    snuff  = Book.create! :title => 'Snuff',          :publishing_year => 2011
    earth  = Book.create! :title => 'The Long Earth', :publishing_year => 2012
    dodger = Book.create! :title => 'Dodger',         :publishing_year => 2012

    index

    expectations = [[snuff, 2011], [earth, 2012]]

    Book.search(:group_by => :publishing_year).each_with_group do |book, group|
      expectation = expectations.shift

      expect(book).to  eq(expectation.first)
      expect(group).to eq(expectation.last)
    end
  end

  it "allows enumerating by group and count" do
    snuff  = Book.create! :title => 'Snuff',          :publishing_year => 2011
    earth  = Book.create! :title => 'The Long Earth', :publishing_year => 2012
    dodger = Book.create! :title => 'Dodger',         :publishing_year => 2012

    index

    expectations = [[snuff, 2011, 1], [earth, 2012, 2]]
    search       = Book.search(:group_by => :publishing_year)

    search.each_with_group_and_count do |book, group, count|
      expectation = expectations.shift

      expect(book).to  eq(expectation[0])
      expect(group).to eq(expectation[1])
      expect(count).to eq(expectation[2])
    end
  end
end
