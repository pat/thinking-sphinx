# frozen_string_literal: true

module ThinkingSphinx
  module Masks; end
end

require 'active_support/core_ext/object/blank'
require 'thinking_sphinx/masks/pagination_mask'

describe ThinkingSphinx::Masks::PaginationMask do
  let(:search) { double('search', :options => {}, :meta => {},
    :per_page => 20, :current_page => 1) }
  let(:mask)   { ThinkingSphinx::Masks::PaginationMask.new search }

  describe '#first_page?' do
    it "returns true when on the first page" do
      expect(mask).to be_first_page
    end

    it "returns false on other pages" do
      allow(search).to receive_messages :current_page => 2

      expect(mask).not_to be_first_page
    end
  end

  describe '#last_page?' do
    before :each do
      search.meta['total'] = '44'
    end

    it "is true when there's no more pages" do
      allow(search).to receive_messages :current_page => 3

      expect(mask).to be_last_page
    end

    it "is false when there's still more pages" do
      expect(mask).not_to be_last_page
    end
  end

  describe '#next_page' do
    before :each do
      search.meta['total'] = '44'
    end

    it "should return one more than the current page" do
      expect(mask.next_page).to eq(2)
    end

    it "should return nil if on the last page" do
      allow(search).to receive_messages :current_page => 3

      expect(mask.next_page).to be_nil
    end
  end

  describe '#next_page?' do
    before :each do
      search.meta['total'] = '44'
    end

    it "is true when there is a second page" do
      expect(mask.next_page?).to be_truthy
    end

    it "is false when there's no more pages" do
      allow(search).to receive_messages :current_page => 3

      expect(mask.next_page?).to be_falsey
    end
  end

  describe '#previous_page' do
    before :each do
      search.meta['total'] = '44'
    end

    it "should return one less than the current page" do
      allow(search).to receive_messages :current_page => 2

      expect(mask.previous_page).to eq(1)
    end

    it "should return nil if on the first page" do
      expect(mask.previous_page).to be_nil
    end
  end

  describe '#total_entries' do
    before :each do
      search.meta['total_found'] = '12'
    end

    it "returns the total found from the search request metadata" do
      expect(mask.total_entries).to eq(12)
    end
  end

  describe '#total_pages' do
    before :each do
      search.meta['total']       = '40'
      search.meta['total_found'] = '44'
    end

    it "uses the total available from the search request metadata" do
      expect(mask.total_pages).to eq(2)
    end

    it "should allow for custom per_page values" do
      allow(search).to receive_messages :per_page => 40

      expect(mask.total_pages).to eq(1)
    end

    it "should return 0 if there is no index and therefore no results" do
      search.meta.clear

      expect(mask.total_pages).to eq(0)
    end
  end
end
