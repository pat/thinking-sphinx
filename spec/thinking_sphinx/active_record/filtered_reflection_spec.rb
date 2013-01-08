require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::FilteredReflection do
  describe '.clone_with_filter' do
    let(:reflection) { double('Reflection', :macro => :has_some,
      :options => options, :active_record => double, :name => 'baz',
      :foreign_type => :foo_type) }
    let(:options)    { {:polymorphic => true} }
    let(:filtered_reflection) { double }

    before :each do
      ThinkingSphinx::ActiveRecord::FilteredReflection.stub(
        :new => filtered_reflection
      )

      reflection.active_record.stub_chain(:connection, :quote_column_name).
        and_return('"foo_type"')
    end

    it "uses the existing reflection's macro" do
      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new).
        with(:has_some, anything, anything, anything)

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "uses the supplied name" do
      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new).
        with(anything, 'foo_bar', anything, anything)

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "uses the existing reflection's parent" do
      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new).
        with(anything, anything, anything, reflection.active_record)

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "removes the polymorphic setting from the options" do
      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new) do |macro, name, options, parent|
        options[:polymorphic].should be_nil
      end

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "adds the class name option" do
      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new) do |macro, name, options, parent|
        options[:class_name].should == 'Bar'
      end

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "sets the foreign key if necessary" do
      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new) do |macro, name, options, parent|
        options[:foreign_key].should == 'baz_id'
      end

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "respects supplied foreign keys" do
      options[:foreign_key] = 'qux_id'

      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new) do |macro, name, options, parent|
        options[:foreign_key].should == 'qux_id'
      end

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "sets conditions if there are none" do
      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new) do |macro, name, options, parent|
        options[:conditions].should == "::ts_join_alias::.\"foo_type\" = 'Bar'"
      end

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "appends to the conditions array" do
      options[:conditions] = ['existing']

      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new) do |macro, name, options, parent|
        options[:conditions].should == ['existing', "::ts_join_alias::.\"foo_type\" = 'Bar'"]
      end

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "extends the conditions hash" do
      options[:conditions] = {:x => :y}

      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new) do |macro, name, options, parent|
        options[:conditions].should == {:x => :y, :foo_type => 'Bar'}
      end

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "appends to the conditions string" do
      options[:conditions] = 'existing'

      ThinkingSphinx::ActiveRecord::FilteredReflection.should_receive(:new) do |macro, name, options, parent|
        options[:conditions].should == "existing AND ::ts_join_alias::.\"foo_type\" = 'Bar'"
      end

      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "returns the new reflection" do
      ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
        reflection, 'foo_bar', 'Bar'
      ).should == filtered_reflection
    end
  end
end
