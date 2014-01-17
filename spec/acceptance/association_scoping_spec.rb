require 'acceptance/spec_helper'

describe 'Scoping association search calls by foreign keys', :live => true do
  describe 'for ActiveRecord indices' do
    it "limits results to those matching the foreign key" do
      pat       = User.create :name => 'Pat'
      melbourne = Article.create :title => 'Guide to Melbourne', :user => pat
      paul      = User.create :name => 'Paul'
      dublin    = Article.create :title => 'Guide to Dublin',    :user => paul
      index

      pat.articles.search('Guide').to_a.should == [melbourne]
    end

    it "limits id-only results to those matching the foreign key" do
      pat       = User.create :name => 'Pat'
      melbourne = Article.create :title => 'Guide to Melbourne', :user => pat
      paul      = User.create :name => 'Paul'
      dublin    = Article.create :title => 'Guide to Dublin',    :user => paul
      index

      pat.articles.search_for_ids('Guide').to_a.should == [melbourne.id]
    end
  end

  describe 'for real-time indices' do
    it "limits results to those matching the foreign key" do
      porsche = Manufacturer.create :name => 'Porsche'
      spyder = Car.create :name => '918 Spyder', :manufacturer => porsche

      audi = Manufacturer.create :name => 'Audi'
      r_eight = Car.create :name => 'R8 Spyder', :manufacturer => audi

      porsche.cars.search('Spyder').to_a.should == [spyder]
    end

    it "limits id-only results to those matching the foreign key" do
      porsche = Manufacturer.create :name => 'Porsche'
      spyder = Car.create :name => '918 Spyder', :manufacturer => porsche

      audi = Manufacturer.create :name => 'Audi'
      r_eight = Car.create :name => 'R8 Spyder', :manufacturer => audi

      porsche.cars.search_for_ids('Spyder').to_a.should == [spyder.id]
    end
  end
end
