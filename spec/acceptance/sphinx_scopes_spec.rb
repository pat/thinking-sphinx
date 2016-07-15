require 'acceptance/spec_helper'

describe 'Sphinx scopes', :live => true do
  it "allows calling sphinx scopes from models" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    index

    expect(Book.by_year(2009).to_a).to eq([grave])
  end

  it "allows scopes to return both query and options" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    index

    expect(Book.by_query_and_year('Graveyard', 2009).to_a).to eq([grave])
  end

  it "allows chaining of scopes" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    index

    expect(Book.by_year(2001..2005).ordered.to_a).to eq([boys, gods])
  end

  it "allows chaining of scopes that include queries" do
    gods  = Book.create! :title => 'American Gods',      :year => 2001
    boys  = Book.create! :title => 'Anansi Boys',        :year => 2005
    grave = Book.create! :title => 'The Graveyard Book', :year => 2009
    index

    expect(Book.by_year(2001).by_query_and_year('Graveyard', 2009).to_a).
      to eq([grave])
  end

  it "allows further search calls on scopes" do
    gaiman    = Book.create! :title => 'American Gods'
    pratchett = Book.create! :title => 'Small Gods'
    index

    expect(Book.by_query('Gods').search('Small').to_a).to eq([pratchett])
  end

  it "allows facet calls on scopes" do
    Book.create! :title => 'American Gods', :author => 'Neil Gaiman'
    Book.create! :title => 'Anansi Boys',   :author => 'Neil Gaiman'
    Book.create! :title => 'Small Gods',    :author => 'Terry Pratchett'
    index

    expect(Book.by_query('Gods').facets.to_hash[:author]).to eq({
      'Neil Gaiman' => 1, 'Terry Pratchett' => 1
    })
  end

  it "allows accessing counts on scopes" do
    Book.create! :title => 'American Gods'
    Book.create! :title => 'Anansi Boys'
    Book.create! :title => 'Small Gods'
    Book.create! :title => 'Night Watch'
    index

    expect(Book.by_query('gods').count).to eq(2)
  end

  it 'raises an exception when trying to modify a populated request' do
    request = Book.by_query('gods')
    request.count

    expect { request.search('foo') }.to raise_error(
      ThinkingSphinx::PopulatedResultsError
    )
  end
end
