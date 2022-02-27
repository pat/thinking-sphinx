# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Updates to records in real-time indices', :live => true do
  it "handles fields with unicode nulls" do
    product = Product.create! :name => "Widget \u0000"

    expect(Product.search.first).to eq(product)
  end unless ENV['DATABASE'] == 'postgresql'

  it "handles attributes for sortable fields accordingly" do
    product = Product.create! :name => 'Red Fish'
    product.update :name => 'Blue Fish'

    expect(Product.search('blue fish', :indices => ['product_core']).to_a).
      to eq([product])
  end

  it "handles inserts and updates for namespaced models" do
    person = Admin::Person.create :name => 'Death'

    expect(Admin::Person.search('Death').to_a).to eq([person])

    person.update :name => 'Mort'

    expect(Admin::Person.search('Death').to_a).to be_empty
    expect(Admin::Person.search('Mort').to_a).to eq([person])
  end

  it "can use a direct interface for processing records" do
    Admin::Person.connection.execute <<~SQL
      INSERT INTO admin_people (name, created_at, updated_at)
      VALUES ('Pat', now(), now());
    SQL

    expect(Admin::Person.search('Pat').to_a).to be_empty

    instance = Admin::Person.find_by(:name => 'Pat')
    ThinkingSphinx::Processor.new(instance).upsert

    expect(Admin::Person.search('Pat').to_a).to eq([instance])

    Admin::Person.connection.execute <<~SQL
      UPDATE admin_people SET name = 'Patrick' WHERE name = 'Pat';
    SQL

    expect(Admin::Person.search('Patrick').to_a).to be_empty

    instance.reload
    ThinkingSphinx::Processor.new(instance).upsert

    expect(Admin::Person.search('Patrick').to_a).to eq([instance])
  end
end
