require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Field do
  let(:field)        { ThinkingSphinx::ActiveRecord::Field.new model, column }
  let(:column)       { double('column', :__name => :title, :__stack => [],
    :string? => false) }
  let(:model)        { double('model') }

  before :each do
    allow(column).to receive_messages :to_a => [column]
  end

  describe '#columns' do
    it 'returns the provided Column object' do
      expect(field.columns).to eq([column])
    end

    it 'translates symbols to Column objects' do
      expect(ThinkingSphinx::ActiveRecord::Column).to receive(:new).with(:title).
        and_return(column)

      ThinkingSphinx::ActiveRecord::Field.new model, :title
    end
  end

  describe '#file?' do
    it "defaults to false" do
      expect(field).not_to be_file
    end

    it "is true if file option is set" do
      field = ThinkingSphinx::ActiveRecord::Field.new model, column,
        :file => true
      expect(field).to be_file
    end
  end

  describe '#with_attribute?' do
    it "defaults to false" do
      expect(field).not_to be_with_attribute
    end

    it "is true if the field is sortable" do
      field = ThinkingSphinx::ActiveRecord::Field.new model, column,
        :sortable => true
      expect(field).to be_with_attribute
    end
  end
end
