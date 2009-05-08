require 'spec/spec_helper'

describe ThinkingSphinx::FacetCollection do
  before do
    @facet_collection = ThinkingSphinx::FacetCollection.new([])
  end

  # TODO fix nasty hack when we have internet!
  def mock_results
    return @results if defined? @results
    @result = Person.find(:first)
    @results = [@result]
    @results.stub!(:each_with_groupby_and_count).and_yield(@result, @result.city.to_crc32, 1)
    @results
  end

  describe "#add_from_results" do
    describe "with empty result set" do
      before do
        @facet_collection.add_from_results('attribute_facet', [])
      end

      it "should add key as attribute" do
        @facet_collection.should have_key(:attribute)
      end

      it "should return an empty hash for the facet results" do
        @facet_collection[:attribute].should be_empty
      end
    end

    describe "with non-empty result set" do
      before do
        @facet_collection.add_from_results('city_facet', mock_results)
      end

      it "should return a hash" do
        @facet_collection.should be_a_kind_of(Hash)
      end

      it "should add key as attribute" do
        @facet_collection.keys.should include(:city)
      end

      it "should return a hash" do
        @facet_collection[:city].should == {@result.city => 1}
      end
    end
  end

  describe "#for" do
    before do
      @facet_collection.add_from_results('city_facet', mock_results)
    end

    it "should return the search results for the attribute and key pair" do
      ThinkingSphinx::Search.should_receive(:search) do |options|
        options[:with].should have_key('city_facet')
        options[:with]['city_facet'].should == @result.city.to_crc32
      end
      @facet_collection.for(:city => @result.city)
    end
  end
end
