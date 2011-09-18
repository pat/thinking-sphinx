require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Field do
  let(:field)        { ThinkingSphinx::ActiveRecord::Field.new column }
  let(:column)       { double('column', :__name => :title, :__stack => []) }
  let(:associations) { double('associations', :alias_for => 'articles') }

  describe '#to_group_sql' do
    it "returns the column name as a string" do
      field.to_group_sql(associations).should == 'articles.title'
    end

    it "gets the column's table alias from the associations object" do
      column.stub!(:__stack => [:users, :posts])

      associations.should_receive(:alias_for).with([:users, :posts]).
        and_return('posts')

      field.to_group_sql(associations)
    end
  end

  describe '#to_select_sql' do
    it "returns the column name as a string" do
      field.to_select_sql(associations).should == 'articles.title'
    end

    it "gets the column's table alias from the associations object" do
      column.stub!(:__stack => [:users, :posts])

      associations.should_receive(:alias_for).with([:users, :posts]).
        and_return('posts')

      field.to_select_sql(associations)
    end

    it "returns the column name with an alias when provided" do
      field = ThinkingSphinx::ActiveRecord::Field.new column,
        :as => :subject

      field.to_select_sql(associations).should == 'articles.title AS subject'
    end
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
