require 'spec_helper'

describe ThinkingSphinx::Search do
  let(:search)        { ThinkingSphinx::Search.new }
  let(:context)       { {:results => []} }
  let(:stack)         { double('stack', :call => true) }

  before :each do
    ThinkingSphinx::Search::Context.stub :new => context

    stub_const 'ThinkingSphinx::Middlewares::DEFAULT', stack
  end

  describe '#current_page' do
    it "should return 1 by default" do
      search.current_page.should == 1
    end

    it "should handle string page values" do
      ThinkingSphinx::Search.new(:page => '2').current_page.should == 2
    end

    it "should handle empty string page values" do
      ThinkingSphinx::Search.new(:page => '').current_page.should == 1
    end

    it "should return the requested page" do
      ThinkingSphinx::Search.new(:page => 10).current_page.should == 10
    end
  end

  describe '#empty?' do
    it "returns false if there is anything in the data set" do
      context[:results] << double

      search.should_not be_empty
    end

    it "returns true if the data set is empty" do
      context[:results].clear

      search.should be_empty
    end
  end

  describe '#initialize' do
    it "lazily loads by default" do
      stack.should_not_receive(:call)

      ThinkingSphinx::Search.new
    end

    it "should automatically populate when :populate is set to true" do
      stack.should_receive(:call).and_return(true)

      ThinkingSphinx::Search.new(:populate => true)
    end
  end

  describe '#offset' do
    it "should default to 0" do
      search.offset.should == 0
    end

    it "should increase by the per_page value for each page in" do
      ThinkingSphinx::Search.new(:per_page => 25, :page => 2).offset.
        should == 25
    end

    it "should prioritise explicit :offset over calculated if given" do
      ThinkingSphinx::Search.new(:offset => 5).offset.should == 5
    end
  end

  describe '#page' do
    it "sets the current page" do
      search.page(3)
      search.current_page.should == 3
    end

    it "returns the search object" do
      search.page(2).should == search
    end
  end

  describe '#per' do
    it "sets the current per_page value" do
      search.per(29)
      search.per_page.should == 29
    end

    it "returns the search object" do
      search.per(29).should == search
    end
  end

  describe '#per_page' do
    it "defaults to 20" do
      search.per_page.should == 20
    end

    it "is set as part of the search options" do
      ThinkingSphinx::Search.new(:per_page => 10).per_page.should == 10
    end

    it "should prioritise :limit over :per_page if given" do
      ThinkingSphinx::Search.new(:per_page => 30, :limit => 40).per_page.
        should == 40
    end

    it "should allow for string arguments" do
      ThinkingSphinx::Search.new(:per_page => '10').per_page.should == 10
    end

    it "allows setting of the per_page value" do
      search.per_page(24)
      search.per_page.should == 24
    end
  end

  describe '#populate' do
    it "runs the middleware" do
      stack.should_receive(:call).with([context]).and_return(true)

      search.populate
    end

    it "does not retrieve results twice" do
      stack.should_receive(:call).with([context]).once.and_return(true)

      search.populate
      search.populate
    end

    it "raises an error if any of the models don't have an index" do
      model_without_index = Class.new(ActiveRecord::Base) do
        def self.name; "ModelWithoutIndex"; end
      end

      model_with_index = Class.new(ActiveRecord::Base) do
        include ThinkingSphinx::ActiveRecord::Base

        def self.name; "ModelWithIndex"; end
      end

      ThinkingSphinx::Index.define :model_with_index, :with => :active_record

      lambda {
        ThinkingSphinx::Search.new(
          :classes => [model_with_index, model_without_index]).populate
      }.should raise_error ThinkingSphinx::MissingIndexError,
        /\(ModelWithoutIndex\)/
    end
  end

  describe '#respond_to?' do
    it "should respond to Array methods" do
      search.respond_to?(:each).should be_true
    end

    it "should respond to Search methods" do
      search.respond_to?(:per_page).should be_true
    end
  end

  describe '#to_a' do
    it "returns each of the standard ActiveRecord objects" do
      unglazed = double('unglazed instance')
      glazed   = double('glazed instance', :unglazed => unglazed)

      context[:results] << glazed

      search.to_a.first.__id__.should == unglazed.__id__
    end
  end
end
