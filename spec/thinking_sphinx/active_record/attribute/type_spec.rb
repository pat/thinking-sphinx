module ThinkingSphinx
  module ActiveRecord
    class Attribute; end
  end
end

require 'thinking_sphinx/errors'
require 'thinking_sphinx/active_record/attribute/type'

describe ThinkingSphinx::ActiveRecord::Attribute::Type do
  let(:type) {
    ThinkingSphinx::ActiveRecord::Attribute::Type.new attribute, model }
  let(:attribute) { double('attribute', :columns => [column], :options => {}) }
  let(:model)     { double('model', :columns => [db_column]) }
  let(:column)    { double('column', :__name => :created_at, :string? => false,
    :__stack => []) }
  let(:db_column) { double('column', :name => 'created_at',
    :type => :integer) }

  describe '#multi?' do
    let(:association) { double('association', :klass => double) }

    before :each do
      column.__stack << :foo

      allow(model).to receive(:reflect_on_association).and_return(association)
    end

    it "returns true if there are has_many associations" do
      allow(association).to receive(:macro).and_return(:has_many)

      expect(type).to be_multi
    end

    it "returns true if there are has_and_belongs_to_many associations" do
      allow(association).to receive(:macro).and_return(:has_and_belongs_to_many)

      expect(type).to be_multi
    end

    it "returns false if there are no associations" do
      column.__stack.clear

      expect(type).not_to be_multi
    end

    it "returns false if there are only belongs_to associations" do
      allow(association).to receive(:macro).and_return(:belongs_to)

      expect(type).not_to be_multi
    end

    it "returns false if there are only has_one associations" do
      allow(association).to receive(:macro).and_return(:has_one)

      expect(type).not_to be_multi
    end

    it "returns true if deeper associations have many" do
      column.__stack << :bar
      deep_association = double(:klass => double, :macro => :has_many)

      allow(association).to receive(:macro).and_return(:belongs_to)
      allow(association).to receive(:klass).and_return(
        double(:reflect_on_association => deep_association)
      )

      expect(type).to be_multi
    end

    it "respects the provided setting" do
      attribute.options[:multi] = true

      expect(type).to be_multi
    end
  end

  describe '#type' do
    it "returns the type option provided" do
      attribute.options[:type] = :datetime

      expect(type.type).to eq(:datetime)
    end

    it "detects integer types from the database" do
      allow(db_column).to receive_messages(:type => :integer, :sql_type => 'integer(11)')

      expect(type.type).to eq(:integer)
    end

    it "detects boolean types from the database" do
      allow(db_column).to receive_messages(:type => :boolean)

      expect(type.type).to eq(:boolean)
    end

    it "detects datetime types from the database as timestamps" do
      allow(db_column).to receive_messages(:type => :datetime)

      expect(type.type).to eq(:timestamp)
    end

    it "detects date types from the database as timestamps" do
      allow(db_column).to receive_messages(:type => :date)

      expect(type.type).to eq(:timestamp)
    end

    it "detects string types from the database" do
      allow(db_column).to receive_messages(:type => :string)

      expect(type.type).to eq(:string)
    end

    it "detects text types from the database as strings" do
      allow(db_column).to receive_messages(:type => :text)

      expect(type.type).to eq(:string)
    end

    it "detects float types from the database" do
      allow(db_column).to receive_messages(:type => :float)

      expect(type.type).to eq(:float)
    end

    it "detects decimal types from the database as floats" do
      allow(db_column).to receive_messages(:type => :decimal)

      expect(type.type).to eq(:float)
    end

    it "detects big ints as big ints" do
      allow(db_column).to receive_messages :type => :bigint

      expect(type.type).to eq(:bigint)
    end

    it "detects large integers as big ints" do
      allow(db_column).to receive_messages :type => :integer, :sql_type => 'bigint(20)'

      expect(type.type).to eq(:bigint)
    end

    it "detects JSON" do
      allow(db_column).to receive_messages :type => :json

      expect(type.type).to eq(:json)
    end

    it "respects provided type setting" do
      attribute.options[:type] = :timestamp

      expect(type.type).to eq(:timestamp)
    end

    it 'raises an error if the database column does not exist' do
      model.columns.clear

      expect { type.type }.to raise_error(ThinkingSphinx::MissingColumnError)
    end
  end
end
