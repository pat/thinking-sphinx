require 'acceptance/spec_helper'

describe 'Searching across STI models', :live => true do
  it "returns super- and sub-class results" do
    platypus = Animal.create :name => 'Platypus'
    bird     = Bird.create :name => 'Duck'
    index

    Animal.search.to_a.should == [platypus, bird]
  end

  it "limits results based on subclasses" do
    platypus = Animal.create :name => 'Platypus'
    bird     = Bird.create :name => 'Duck'
    index

    Bird.search.to_a.should == [bird]
  end

  it "returns results for deeper subclasses when searching on their parents" do
    platypus = Animal.create :name => 'Platypus'
    bird     = Bird.create :name => 'Duck'
    emu      = FlightlessBird.create :name => 'Emu'
    index

    Bird.search.to_a.should == [bird, emu]
  end

  it "returns results for deeper subclasses" do
    platypus = Animal.create :name => 'Platypus'
    bird     = Bird.create :name => 'Duck'
    emu      = FlightlessBird.create :name => 'Emu'
    index

    FlightlessBird.search.to_a.should == [emu]
  end
end
