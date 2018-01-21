# frozen_string_literal: true

require "acceptance/spec_helper"

describe "Merging deltas", :live => true do
  it "merges in new records" do
    guards = Book.create(
      :title => "Guards! Guards!", :author => "Terry Pratchett"
    )
    sleep 0.25

    expect(
      Book.search("Terry Pratchett", :indices => ["book_delta"]).to_a
    ).to eq([guards])
    expect(
      Book.search("Terry Pratchett", :indices => ["book_core"]).to_a
    ).to be_empty

    merge
    guards.reload

    expect(
      Book.search("Terry Pratchett", :indices => ["book_core"]).to_a
    ).to eq([guards])
    expect(guards.delta).to eq(false)
  end

  it "merges in changed records" do
    race = Book.create(
      :title => "The Hate Space", :author => "Maxine Beneba Clarke"
    )
    index
    expect(
      Book.search("Space", :indices => ["book_core"]).to_a
    ).to eq([race])

    race.reload.update_attributes :title => "The Hate Race"
    sleep 0.25
    expect(
      Book.search("Race", :indices => ["book_delta"]).to_a
    ).to eq([race])
    expect(
      Book.search("Race", :indices => ["book_core"]).to_a
    ).to be_empty

    merge
    race.reload

    expect(
      Book.search("Race", :indices => ["book_core"]).to_a
    ).to eq([race])
    expect(
      Book.search("Race", :indices => ["book_delta"]).to_a
    ).to eq([race])
    expect(
      Book.search("Space", :indices => ["book_core"]).to_a
    ).to be_empty
    expect(race.delta).to eq(false)
  end

  it "maintains existing records" do
    race = Book.create(
      :title => "The Hate Race", :author => "Maxine Beneba Clarke"
    )
    index

    soil = Book.create(
      :title => "Foreign Soil", :author => "Maxine Beneba Clarke"
    )
    sleep 0.25
    expect(
      Book.search("Soil", :indices => ["book_delta"]).to_a
    ).to eq([soil])
    expect(
      Book.search("Soil", :indices => ["book_core"]).to_a
    ).to be_empty
    expect(
      Book.search("Race", :indices => ["book_core"]).to_a
    ).to eq([race])

    merge

    expect(
      Book.search("Soil", :indices => ["book_core"]).to_a
    ).to eq([soil])
    expect(
      Book.search("Race", :indices => ["book_core"]).to_a
    ).to eq([race])
  end
end
