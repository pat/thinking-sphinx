# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Searching across STI models', :live => true do
  it "returns super- and sub-class results" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    index

    expect(Animal.search(:indices  => ['animal_core']).to_a).to eq([platypus, duck])
  end

  it "limits results based on subclasses" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    index

    expect(Bird.search(:indices  => ['animal_core']).to_a).to eq([duck])
  end

  it "returns results for deeper subclasses when searching on their parents" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    emu      = FlightlessBird.create :name => 'Emu'
    index

    expect(Bird.search(:indices  => ['animal_core']).to_a).to eq([duck, emu])
  end

  it "returns results for deeper subclasses" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    emu      = FlightlessBird.create :name => 'Emu'
    index

    expect(FlightlessBird.search(:indices  => ['animal_core']).to_a).to eq([emu])
  end

  it "filters out sibling subclasses" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    otter    = Mammal.create :name => 'Otter'
    index

    expect(Bird.search(:indices  => ['animal_core']).to_a).to eq([duck])
  end

  it "obeys :classes if supplied" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    emu      = FlightlessBird.create :name => 'Emu'
    index

    expect(Bird.search(
      :indices  => ['animal_core'],
      :skip_sti => true,
      :classes  => [Bird, FlightlessBird]
    ).to_a).to eq([duck, emu])
  end

  it 'finds root objects when type is blank' do
    animal = Animal.create :name => 'Animal', type: ''
    index

    expect(Animal.search(:indices => ['animal_core']).to_a).to eq([animal])
  end

  it 'allows for indices on mid-hierarchy classes' do
    duck     = Bird.create :name => 'Duck'
    emu      = FlightlessBird.create :name => 'Emu'
    index

    expect(Bird.search(:indices => ['bird_core']).to_a).to eq([duck, emu])
  end
end
