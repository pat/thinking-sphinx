require 'spec_helper'

describe ThinkingSphinx::Connection do
  describe '.take' do
    let(:pool)             { double 'pool' }
    let(:connection)       { double 'connection', :base_error => StandardError }
    let(:error)            { ThinkingSphinx::QueryExecutionError.new 'failed' }
    let(:translated_error) { ThinkingSphinx::SphinxError.new }

    before :each do
      ThinkingSphinx::Connection.stub :pool => pool
      ThinkingSphinx::SphinxError.stub :new_from_mysql => translated_error
      pool.stub(:take).and_yield(connection)

      error.statement            = 'SELECT * FROM article_core'
      translated_error.statement = 'SELECT * FROM article_core'
    end

    it "yields a connection from the pool" do
      ThinkingSphinx::Connection.take do |c|
        c.should == connection
      end
    end

    it "retries errors once" do
      tries = 0

      lambda {
        ThinkingSphinx::Connection.take do |c|
          tries += 1
          raise error if tries < 2
        end
      }.should_not raise_error
    end

    it "retries errors twice" do
      tries = 0

      lambda {
        ThinkingSphinx::Connection.take do |c|
          tries += 1
          raise error if tries < 3
        end
      }.should_not raise_error
    end

    it "raises a translated error if it fails three times" do
      tries = 0

      lambda {
        ThinkingSphinx::Connection.take do |c|
          tries += 1
          raise error if tries < 4
        end
      }.should raise_error(ThinkingSphinx::SphinxError)
    end

    [ThinkingSphinx::SyntaxError, ThinkingSphinx::ParseError].each do |klass|
      context klass.name do
        let(:translated_error) { klass.new }

        it "raises the error" do
          lambda {
            ThinkingSphinx::Connection.take { |c| raise error }
          }.should raise_error(klass)
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

          yields.should == 1
        end
      end
    end
  end
end
