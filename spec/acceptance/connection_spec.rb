# frozen_string_literal: true

require 'acceptance/spec_helper'

RSpec.describe 'Connections', :live => true do
  let(:maximum)    { (2 ** 23) - 5 }
  let(:query)      { String.new "SELECT * FROM book_core WHERE MATCH('')" }
  let(:difference) { maximum - query.length }

  after :each do
    ThinkingSphinx::Configuration.reset
  end

  it 'allows normal length queries through' do
    expect {
      ThinkingSphinx::Connection.take do |connection|
        connection.execute query.insert(-3, 'a' * difference)
      end
    }.to_not raise_error
  end

  it 'does not allow overly long queries' do
    expect {
      ThinkingSphinx::Connection.take do |connection|
        connection.execute query.insert(-3, 'a' * (difference + 5))
      end
    }.to raise_error(ThinkingSphinx::QueryLengthError)
  end

  it 'does not allow queries longer than specified in the settings' do
    ThinkingSphinx::Configuration.reset
    ThinkingSphinx::Connection.clear

    write_configuration('maximum_statement_length' => maximum - 5)

    expect {
      ThinkingSphinx::Connection.take do |connection|
        connection.execute query.insert(-3, 'a' * difference)
      end
    }.to raise_error(ThinkingSphinx::QueryLengthError)
  end
end
