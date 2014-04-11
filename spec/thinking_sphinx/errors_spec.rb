require 'spec_helper'

describe ThinkingSphinx::SphinxError do
  describe '.new_from_mysql' do
    let(:error) { double 'error', :message => 'index foo: unknown error',
      :backtrace => ['foo', 'bar'] }

    it "translates syntax errors" do
      error.stub :message => 'index foo: syntax error: something is wrong'

      ThinkingSphinx::SphinxError.new_from_mysql(error).
        should be_a(ThinkingSphinx::SyntaxError)
    end

    it "translates parse errors" do
      error.stub :message => 'index foo: parse error: something is wrong'

      ThinkingSphinx::SphinxError.new_from_mysql(error).
        should be_a(ThinkingSphinx::ParseError)
    end

    it "translates query errors" do
      error.stub :message => 'index foo: query error: something is wrong'

      ThinkingSphinx::SphinxError.new_from_mysql(error).
        should be_a(ThinkingSphinx::QueryError)
    end

    it "translates connection errors" do
      error.stub :message => "Can't connect to MySQL server on '127.0.0.1' (61)"

      ThinkingSphinx::SphinxError.new_from_mysql(error).
        should be_a(ThinkingSphinx::ConnectionError)
    end

    it 'prefixes the connection error message' do
      error.stub :message => "Can't connect to MySQL server on '127.0.0.1' (61)"

      ThinkingSphinx::SphinxError.new_from_mysql(error).message.
        should == "Error connecting to Sphinx via the MySQL protocol. Can't connect to MySQL server on '127.0.0.1' (61)"
    end

    it "translates jdbc connection errors" do
      error.stub :message => "Communications link failure"

      ThinkingSphinx::SphinxError.new_from_mysql(error).
        should be_a(ThinkingSphinx::ConnectionError)
    end

    it 'prefixes the jdbc connection error message' do
      error.stub :message => "Communications link failure"

      ThinkingSphinx::SphinxError.new_from_mysql(error).message.
        should == "Error connecting to Sphinx via the MySQL protocol. Communications link failure"
    end

    it "defaults to sphinx errors" do
      error.stub :message => 'index foo: unknown error: something is wrong'

      ThinkingSphinx::SphinxError.new_from_mysql(error).
        should be_a(ThinkingSphinx::SphinxError)
    end

    it "keeps the original error's backtrace" do
      error.stub :message => 'index foo: unknown error: something is wrong'

      ThinkingSphinx::SphinxError.new_from_mysql(error).
        backtrace.should == error.backtrace
    end
  end
end
