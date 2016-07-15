require 'spec_helper'

describe ThinkingSphinx::Connection do
  describe '.take' do
    let(:pool)             { double 'pool' }
    let(:connection)       { double 'connection', :base_error => StandardError }
    let(:error)            { ThinkingSphinx::QueryExecutionError.new 'failed' }
    let(:translated_error) { ThinkingSphinx::SphinxError.new }

    before :each do
      allow(ThinkingSphinx::Connection).to receive_messages :pool => pool
      allow(ThinkingSphinx::SphinxError).to receive_messages :new_from_mysql => translated_error
      allow(pool).to receive(:take).and_yield(connection)

      error.statement            = 'SELECT * FROM article_core'
      translated_error.statement = 'SELECT * FROM article_core'
    end

    it "yields a connection from the pool" do
      ThinkingSphinx::Connection.take do |c|
        expect(c).to eq(connection)
      end
    end

    it "retries errors once" do
      tries = 0

      expect {
        ThinkingSphinx::Connection.take do |c|
          tries += 1
          raise error if tries < 2
        end
      }.not_to raise_error
    end

    it "retries errors twice" do
      tries = 0

      expect {
        ThinkingSphinx::Connection.take do |c|
          tries += 1
          raise error if tries < 3
        end
      }.not_to raise_error
    end

    it "raises a translated error if it fails three times" do
      tries = 0

      expect {
        ThinkingSphinx::Connection.take do |c|
          tries += 1
          raise error if tries < 4
        end
      }.to raise_error(ThinkingSphinx::SphinxError)
    end

    [ThinkingSphinx::SyntaxError, ThinkingSphinx::ParseError].each do |klass|
      context klass.name do
        let(:translated_error) { klass.new }

        it "raises the error" do
          expect {
            ThinkingSphinx::Connection.take { |c| raise error }
          }.to raise_error(klass)
        end

        it "does not yield the connection more than once" do
          yields = 0

          begin
            ThinkingSphinx::Connection.take do |c|
              yields += 1
              raise error
            end
          rescue klass
            #
          end

          expect(yields).to eq(1)
        end
      end
    end
  end
end
