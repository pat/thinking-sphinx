# frozen_string_literal: true

RSpec.describe ThinkingSphinx::Connection::MRI do
  subject { described_class.new :host => "127.0.0.1", :port => 9306 }

  let(:client) { double :client, :query => "result", :next_result => false }

  before :each do
    allow(Mysql2::Client).to receive(:new).and_return(client)
  end

  after :each do
    ThinkingSphinx::Configuration.reset
  end

  describe "#execute" do
    it "sends the query to the client" do
      subject.execute "SELECT QUERY"

      expect(client).to have_received(:query).with("SELECT QUERY")
    end

    it "returns a result" do
      expect(subject.execute("SELECT QUERY")).to eq("result")
    end

    context "with long queries" do
      let(:maximum)    { (2 ** 23) - 5 }
      let(:query)      { String.new "SELECT * FROM book_core WHERE MATCH('')" }
      let(:difference) { maximum - query.length }

      it 'does not allow overly long queries' do
        expect {
          subject.execute(query.insert(-3, 'a' * (difference + 5)))
        }.to raise_error(ThinkingSphinx::QueryLengthError)
      end

      it 'does not allow queries longer than specified in the settings' do
        ThinkingSphinx::Configuration.reset

        write_configuration('maximum_statement_length' => maximum - 5)

        expect {
          subject.execute(query.insert(-3, 'a' * (difference)))
        }.to raise_error(ThinkingSphinx::QueryLengthError)
      end
    end
  end
end if RUBY_PLATFORM != 'java'
