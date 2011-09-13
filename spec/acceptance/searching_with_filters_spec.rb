require 'spec_helper'

describe 'Searching with filters', :live => true do
  it "limits results by single value boolean filters" do
    Article.create! :title => 'Pancakes', :published => true
    Article.create! :title => 'Waffles',  :published => false
    index

    Article.search(:with => {:published => true}).length.should == 1
  end
end
