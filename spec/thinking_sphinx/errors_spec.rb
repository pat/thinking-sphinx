require 'spec_helper'

describe ThinkingSphinx::SphinxError do
  describe '.new_from_mysql' do
    let(:error) { double 'error', :message => 'index foo: unknown error',
      :backtrace => ['foo', 'bar'] }

    it "translates syntax errors" do
      allow(error).to receive_messages :message => 'index foo: syntax error: something is wrong'

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error)).
        to be_a(ThinkingSphinx::SyntaxError)
    end

    it "translates parse errors" do
      allow(error).to receive_messages :message => 'index foo: parse error: something is wrong'

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error)).
        to be_a(ThinkingSphinx::ParseError)
    end

    it "translates 'query is non-computable' errors" do
      allow(error).to receive_messages :message => 'index model_core: query is non-computable (single NOT operator)'

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error)).
        to be_a(ThinkingSphinx::ParseError)
    end

    it "translates query errors" do
      allow(error).to receive_messages :message => 'index foo: query error: something is wrong'

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error)).
        to be_a(ThinkingSphinx::QueryError)
    end

    it "translates connection errors" do
      allow(error).to receive_messages :message => "Can't connect to MySQL server on '127.0.0.1' (61)"

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error)).
        to be_a(ThinkingSphinx::ConnectionError)
    end

    it 'translates out-of-bounds errors' do
      allow(error).to receive_messages :message => "offset out of bounds (offset=1001, max_matches=1000)"

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error)).
        to be_a(ThinkingSphinx::OutOfBoundsError)
    end

    it 'prefixes the connection error message' do
      allow(error).to receive_messages :message => "Can't connect to MySQL server on '127.0.0.1' (61)"

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error).message).
        to eq("Error connecting to Sphinx via the MySQL protocol. Can't connect to MySQL server on '127.0.0.1' (61)")
    end

    it "translates jdbc connection errors" do
      allow(error).to receive_messages :message => "Communications link failure"

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error)).
        to be_a(ThinkingSphinx::ConnectionError)
    end

    it 'prefixes the jdbc connection error message' do
      allow(error).to receive_messages :message => "Communications link failure"

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error).message).
        to eq("Error connecting to Sphinx via the MySQL protocol. Communications link failure")
    end

    it "defaults to sphinx errors" do
      allow(error).to receive_messages :message => 'index foo: unknown error: something is wrong'

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error)).
        to be_a(ThinkingSphinx::SphinxError)
    end

    it "keeps the original error's backtrace" do
      allow(error).to receive_messages :message => 'index foo: unknown error: something is wrong'

      expect(ThinkingSphinx::SphinxError.new_from_mysql(error).
        backtrace).to eq(error.backtrace)
    end
  end
end
