module ThinkingSphinx
  module Masks; end
end

require 'thinking_sphinx/masks/scopes_mask'

describe ThinkingSphinx::Masks::ScopesMask do
  let(:search) { double('search', :options => {}, :per_page => 20,
    :populated? => false) }
  let(:mask)   { ThinkingSphinx::Masks::ScopesMask.new search }

  before :each do
    FileUtils.stub :mkdir_p => true
  end

  describe '#search' do
    it "replaces the query if one is supplied" do
      search.should_receive(:query=).with('bar')

      mask.search('bar')
    end

    it "keeps the existing query when only options are offered" do
      search.should_not_receive(:query=)

      mask.search :with => {:foo => :bar}
    end

    it "merges conditions" do
      search.options[:conditions] = {:foo => 'bar'}

      mask.search :conditions => {:baz => 'qux'}

      search.options[:conditions].should == {:foo => 'bar', :baz => 'qux'}
    end

    it "merges filters" do
      search.options[:with] = {:foo => :bar}

      mask.search :with => {:baz => :qux}

      search.options[:with].should == {:foo => :bar, :baz => :qux}
    end

    it "merges exclusive filters" do
      search.options[:without] = {:foo => :bar}

      mask.search :without => {:baz => :qux}

      search.options[:without].should == {:foo => :bar, :baz => :qux}
    end

    it "appends excluded ids" do
      search.options[:without_ids] = [1, 3]

      mask.search :without_ids => [5, 7]

      search.options[:without_ids].should == [1, 3, 5, 7]
    end

    it "replaces the retry_stale option" do
      search.options[:retry_stale] = true

      mask.search :retry_stale => 6

      search.options[:retry_stale].should == 6
    end

    it "returns the original search object" do
      mask.search.object_id.should == search.object_id
    end
  end

  describe '#search_for_ids' do
    it "replaces the query if one is supplied" do
      search.should_receive(:query=).with('bar')

      mask.search_for_ids('bar')
    end

    it "keeps the existing query when only options are offered" do
      search.should_not_receive(:query=)

      mask.search_for_ids :with => {:foo => :bar}
    end

    it "merges conditions" do
      search.options[:conditions] = {:foo => 'bar'}

      mask.search_for_ids :conditions => {:baz => 'qux'}

      search.options[:conditions].should == {:foo => 'bar', :baz => 'qux'}
    end

    it "merges filters" do
      search.options[:with] = {:foo => :bar}

      mask.search_for_ids :with => {:baz => :qux}

      search.options[:with].should == {:foo => :bar, :baz => :qux}
    end

    it "merges exclusive filters" do
      search.options[:without] = {:foo => :bar}

      mask.search_for_ids :without => {:baz => :qux}

      search.options[:without].should == {:foo => :bar, :baz => :qux}
    end

    it "appends excluded ids" do
      search.options[:without_ids] = [1, 3]

      mask.search_for_ids :without_ids => [5, 7]

      search.options[:without_ids].should == [1, 3, 5, 7]
    end

    it "replaces the retry_stale option" do
      search.options[:retry_stale] = true

      mask.search_for_ids :retry_stale => 6

      search.options[:retry_stale].should == 6
    end

    it "adds the ids_only option" do
      mask.search_for_ids

      search.options[:ids_only].should be_true
    end

    it "returns the original search object" do
      mask.search_for_ids.object_id.should == search.object_id
    end
  end
end
