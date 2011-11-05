require 'acceptance/spec_helper'

describe 'Searching across STI models', :live => true do
  it "returns super- and sub-class results" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    index

    Animal.search.to_a.should == [platypus, duck]
  end

  it "limits results based on subclasses" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    index

    Bird.search.to_a.should == [duck]
  end

  it "returns results for deeper subclasses when searching on their parents" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    emu      = FlightlessBird.create :name => 'Emu'
    index

    Bird.search.to_a.should == [duck, emu]
  end

  it "returns results for deeper subclasses" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    emu      = FlightlessBird.create :name => 'Emu'
    index

    FlightlessBird.search.to_a.should == [emu]
  end

  it "filters out sibling subclasses" do
    platypus = Animal.create :name => 'Platypus'
    duck     = Bird.create :name => 'Duck'
    otter    = Mammal.create :name => 'Otter'
    index

    Bird.search.to_a.should == [duck]
  end
end
