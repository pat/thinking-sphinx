module ThinkingSphinx
  module Masks; end
end

require 'thinking_sphinx/masks/scopes_mask'

describe ThinkingSphinx::Masks::ScopesMask do
  let(:search) { double('search', :options => {}, :per_page => 20,
    :populated? => false) }
  let(:mask)   { ThinkingSphinx::Masks::ScopesMask.new search }

  before :each do
    allow(FileUtils).to receive_messages :mkdir_p => true
  end

  describe '#search' do
    it "replaces the query if one is supplied" do
      expect(search).to receive(:query=).with('bar')

      mask.search('bar')
    end

    it "keeps the existing query when only options are offered" do
      expect(search).not_to receive(:query=)

      mask.search :with => {:foo => :bar}
    end

    it "merges conditions" do
      search.options[:conditions] = {:foo => 'bar'}

      mask.search :conditions => {:baz => 'qux'}

      expect(search.options[:conditions]).to eq({:foo => 'bar', :baz => 'qux'})
    end

    it "merges filters" do
      search.options[:with] = {:foo => :bar}

      mask.search :with => {:baz => :qux}

      expect(search.options[:with]).to eq({:foo => :bar, :baz => :qux})
    end

    it "merges exclusive filters" do
      search.options[:without] = {:foo => :bar}

      mask.search :without => {:baz => :qux}

      expect(search.options[:without]).to eq({:foo => :bar, :baz => :qux})
    end

    it "appends excluded ids" do
      search.options[:without_ids] = [1, 3]

      mask.search :without_ids => [5, 7]

      expect(search.options[:without_ids]).to eq([1, 3, 5, 7])
    end

    it "replaces the retry_stale option" do
      search.options[:retry_stale] = true

      mask.search :retry_stale => 6

      expect(search.options[:retry_stale]).to eq(6)
    end

    it "returns the original search object" do
      expect(mask.search.object_id).to eq(search.object_id)
    end
  end

  describe '#search_for_ids' do
    it "replaces the query if one is supplied" do
      expect(search).to receive(:query=).with('bar')

      mask.search_for_ids('bar')
    end

    it "keeps the existing query when only options are offered" do
      expect(search).not_to receive(:query=)

      mask.search_for_ids :with => {:foo => :bar}
    end

    it "merges conditions" do
      search.options[:conditions] = {:foo => 'bar'}

      mask.search_for_ids :conditions => {:baz => 'qux'}

      expect(search.options[:conditions]).to eq({:foo => 'bar', :baz => 'qux'})
    end

    it "merges filters" do
      search.options[:with] = {:foo => :bar}

      mask.search_for_ids :with => {:baz => :qux}

      expect(search.options[:with]).to eq({:foo => :bar, :baz => :qux})
    end

    it "merges exclusive filters" do
      search.options[:without] = {:foo => :bar}

      mask.search_for_ids :without => {:baz => :qux}

      expect(search.options[:without]).to eq({:foo => :bar, :baz => :qux})
    end

    it "appends excluded ids" do
      search.options[:without_ids] = [1, 3]

      mask.search_for_ids :without_ids => [5, 7]

      expect(search.options[:without_ids]).to eq([1, 3, 5, 7])
    end

    it "replaces the retry_stale option" do
      search.options[:retry_stale] = true

      mask.search_for_ids :retry_stale => 6

      expect(search.options[:retry_stale]).to eq(6)
    end

    it "adds the ids_only option" do
      mask.search_for_ids

      expect(search.options[:ids_only]).to be_truthy
    end

    it "returns the original search object" do
      expect(mask.search_for_ids.object_id).to eq(search.object_id)
    end
  end
end
