# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Searching by latitude and longitude', :live => true do
  it "orders by distance" do
    mel = City.create :name => 'Melbourne', :lat => -0.6599720, :lng => 2.530082
    syd = City.create :name => 'Sydney',    :lat => -0.5909679, :lng => 2.639131
    bri = City.create :name => 'Brisbane',  :lat => -0.4794031, :lng => 2.670838
    index

    expect(City.search(:geo => [-0.616241, 2.602712], :order => 'geodist ASC').
      to_a).to eq([syd, mel, bri])
  end

  it "filters by distance" do
    mel = City.create :name => 'Melbourne', :lat => -0.6599720, :lng => 2.530082
    syd = City.create :name => 'Sydney',    :lat => -0.5909679, :lng => 2.639131
    bri = City.create :name => 'Brisbane',  :lat => -0.4794031, :lng => 2.670838
    index

    expect(City.search(
      :geo  => [-0.616241, 2.602712],
      :with => {:geodist => 0.0..470_000.0}
    ).to_a).to eq([mel, syd])
  end

  it "provides the distance for each search result" do
    mel = City.create :name => 'Melbourne', :lat => -0.6599720, :lng => 2.530082
    syd = City.create :name => 'Sydney',    :lat => -0.5909679, :lng => 2.639131
    bri = City.create :name => 'Brisbane',  :lat => -0.4794031, :lng => 2.670838
    index

    cities = City.search(:geo => [-0.616241, 2.602712], :order => 'geodist ASC')
    if ENV.fetch('SPHINX_VERSION', '2.1.2').to_f > 2.1
      expected = {:mysql => 249907.171875, :postgresql => 249912.03125}
    else
      expected = {:mysql => 250326.906250, :postgresql => 250331.234375}
    end

    if ActiveRecord::Base.configurations['test']['adapter'][/postgres/]
      expect(cities.first.geodist).to be_within(0.01).of(expected[:postgresql])
    else # mysql
      expect(cities.first.geodist).to be_within(0.01).of(expected[:mysql])
    end
  end

  it "handles custom select clauses that refer to the distance" do
    mel = City.create :name => 'Melbourne', :lat => -0.6599720, :lng => 2.530082
    syd = City.create :name => 'Sydney',    :lat => -0.5909679, :lng => 2.639131
    bri = City.create :name => 'Brisbane',  :lat => -0.4794031, :lng => 2.670838
    index

    expect(City.search(
      :geo  => [-0.616241, 2.602712],
      :with => {:geodist => 0.0..470_000.0},
      :select => "*, geodist as custom_weight"
    ).to_a).to eq([mel, syd])
  end
end
