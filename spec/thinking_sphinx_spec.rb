# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx do
  describe '.count' do
    let(:search) { double('search', :total_entries => 23, :populated? => false,
      :options => {}) }

    before :each do
      allow(ThinkingSphinx::Search).to receive_messages :new => search
    end

    it "returns the total entries of the search object" do
      expect(ThinkingSphinx.count).to eq(search.total_entries)
    end

    it "passes through the given query and options" do
      expect(ThinkingSphinx::Search).to receive(:new).with('foo', :bar => :baz).
        and_return(search)

      ThinkingSphinx.count('foo', :bar => :baz)
    end
  end

  describe '.search' do
    let(:search) { double('search') }

    before :each do
      allow(ThinkingSphinx::Search).to receive_messages :new => search
    end

    it "returns a new search object" do
      expect(ThinkingSphinx.search).to eq(search)
    end

    it "passes through the given query and options" do
      expect(ThinkingSphinx::Search).to receive(:new).with('foo', :bar => :baz).
        and_return(search)

      ThinkingSphinx.search('foo', :bar => :baz)
    end
  end
end
