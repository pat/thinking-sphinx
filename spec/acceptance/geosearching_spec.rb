require 'acceptance/spec_helper'

describe 'Searching by latitude and longitude', :live => true do
  it "orders by distance" do
    mel = City.create :name => 'Melbourne', :lat => -0.6599720, :lng => 2.530082
    syd = City.create :name => 'Sydney',    :lat => -0.5909679, :lng => 2.639131
    bri = City.create :name => 'Brisbane',  :lat => -0.4794031, :lng => 2.670838
    index

    City.search(:geo => [-0.616241, 2.602712], :order => 'geodist ASC').
      to_a.should == [syd, mel, bri]
  end

  it "filters by distance" do
    mel = City.create :name => 'Melbourne', :lat => -0.6599720, :lng => 2.530082
    syd = City.create :name => 'Sydney',    :lat => -0.5909679, :lng => 2.639131
    bri = City.create :name => 'Brisbane',  :lat => -0.4794031, :lng => 2.670838
    index

    City.search(
      :geo  => [-0.616241, 2.602712],
      :with => {:geodist => 0.0..470_000.0}
    ).to_a.should == [mel, syd]
  end

  it "provides the distance for each search result" do
    mel = City.create :name => 'Melbourne', :lat => -0.6599720, :lng => 2.530082
    syd = City.create :name => 'Sydney',    :lat => -0.5909679, :lng => 2.639131
    bri = City.create :name => 'Brisbane',  :lat => -0.4794031, :lng => 2.670838
    index

    cities = City.search(:geo => [-0.616241, 2.602712], :order => 'geodist ASC')
    if ENV['SPHINX_VERSION'].try :[], /2.2.\d/
      expected = {:mysql => 249907.171875, :postgresql => 249912.03125}
    else
      expected = {:mysql => 250326.906250, :postgresql => 250331.234375}
    end

    if ActiveRecord::Base.configurations['test']['adapter'][/postgres/]
      cities.first.geodist.should == expected[:postgresql]
    else # mysql
      cities.first.geodist.should == expected[:mysql]
    end
  end

  it "handles custom select clauses that refer to the distance" do
    mel = City.create :name => 'Melbourne', :lat => -0.6599720, :lng => 2.530082
    syd = City.create :name => 'Sydney',    :lat => -0.5909679, :lng => 2.639131
    bri = City.create :name => 'Brisbane',  :lat => -0.4794031, :lng => 2.670838
    index

    City.search(
      :geo  => [-0.616241, 2.602712],
      :with => {:geodist => 0.0..470_000.0},
      :select => "*, geodist as custom_weight"
    ).to_a.should == [mel, syd]
  end
end
