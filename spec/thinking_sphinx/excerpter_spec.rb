# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::Excerpter do
  let(:excerpter)  { ThinkingSphinx::Excerpter.new('index', 'all words') }
  let(:connection) {
    double('connection', :execute => [{'snippet' => 'some highlighted words'}])
  }

  before :each do
    allow(ThinkingSphinx::Connection).to receive(:take).and_yield(connection)
    allow(Riddle::Query).to receive_messages :snippets => 'CALL SNIPPETS'
  end

  describe '#excerpt!' do
    it "generates a snippets call" do
      expect(Riddle::Query).to receive(:snippets).
        with('all of the words', 'index', 'all words',
          ThinkingSphinx::Excerpter::DefaultOptions).
        and_return('CALL SNIPPETS')

      excerpter.excerpt!('all of the words')
    end

    it "respects the provided options" do
      excerpter = ThinkingSphinx::Excerpter.new('index', 'all words',
        :before_match => '<b>', :chunk_separator => ' -- ')

      expect(Riddle::Query).to receive(:snippets).
        with('all of the words', 'index', 'all words',
          :before_match => '<b>', :after_match => '</span>',
          :chunk_separator => ' -- ').
        and_return('CALL SNIPPETS')

      excerpter.excerpt!('all of the words')
    end

    it "sends the snippets call to Sphinx" do
      expect(connection).to receive(:execute).with('CALL SNIPPETS').
        and_return([{'snippet' => ''}])

      excerpter.excerpt!('all of the words')
    end

    it "returns the first value returned by Sphinx" do
      allow(connection).to receive_messages :execute => [{'snippet' => 'some highlighted words'}]

      expect(excerpter.excerpt!('all of the words')).to eq('some highlighted words')
    end
  end
end
