require 'spec_helper'

describe ThinkingSphinx::Excerpter do
  let(:excerpter)  { ThinkingSphinx::Excerpter.new('index', 'all words') }
  let(:connection) {
    double('connection', :query => [{'snippet' => 'some highlighted words'}])
  }

  before :each do
    ThinkingSphinx::Connection.stub :new => connection
    Riddle::Query.stub :snippets => 'CALL SNIPPETS'
  end

  describe '#excerpt!' do
    it "generates a snippets call" do
      Riddle::Query.should_receive(:snippets).
        with('all of the words', 'index', 'all words',
          ThinkingSphinx::Excerpter::DefaultOptions).
        and_return('CALL SNIPPETS')

      excerpter.excerpt!('all of the words')
    end

    it "respects the provided options" do
      excerpter = ThinkingSphinx::Excerpter.new('index', 'all words',
        :before_match => '<b>', :chunk_separator => ' -- ')

      Riddle::Query.should_receive(:snippets).
        with('all of the words', 'index', 'all words',
          :before_match => '<b>', :after_match => '</span>',
          :chunk_separator => ' -- ').
        and_return('CALL SNIPPETS')

      excerpter.excerpt!('all of the words')
    end

    it "sends the snippets call to Sphinx" do
      connection.should_receive(:query).with('CALL SNIPPETS').
        and_return([{'snippet' => ''}])

      excerpter.excerpt!('all of the words')
    end

    it "returns the first value returned by Sphinx" do
      connection.stub :query => [{'snippet' => 'some highlighted words'}]

      excerpter.excerpt!('all of the words').should == 'some highlighted words'
    end
  end
end
