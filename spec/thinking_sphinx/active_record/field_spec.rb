require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Field do
  let(:field)        { ThinkingSphinx::ActiveRecord::Field.new column }
  let(:column)       {
    double('column', :__name => :title, :__stack => [], :string? => false)
  }
  let(:associations) { double('associations', :alias_for => 'articles') }
  let(:source)       { double('source') }

  before :each do
    column.stub! :to_a => [column]
  end

  describe '#with_attribute?' do
    it "defaults to false" do
      field.should_not be_with_attribute
    end

    it "is true if the field is sortable" do
      field = ThinkingSphinx::ActiveRecord::Field.new column, :sortable => true
      field.should be_with_attribute
    end
  end
end
