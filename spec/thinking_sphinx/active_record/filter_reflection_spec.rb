require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::FilterReflection do
  describe '.call' do
    let(:reflection) { double('Reflection', :macro => :has_some,
      :options => options, :active_record => double, :name => 'baz',
      :foreign_type => :foo_type, :class => reflection_klass) }
    let(:options)    { {:polymorphic => true} }
    let(:filtered_reflection) { double 'filtered reflection' }
    let(:reflection_klass)    { double :new => filtered_reflection }

    before :each do
      reflection.active_record.stub_chain(:connection, :quote_column_name).
        and_return('"foo_type"')
    end

    it "uses the existing reflection's macro" do
      reflection_klass.should_receive(:new).
        with(:has_some, anything, anything, anything)

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "uses the supplied name" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        reflection_klass.should_receive(:new).
          with('foo_bar', anything, anything, anything)
      else
        reflection_klass.should_receive(:new).
          with(anything, 'foo_bar', anything, anything)
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "uses the existing reflection's parent" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        reflection_klass.should_receive(:new).
          with(anything, anything, anything, reflection.active_record)
      else
        reflection_klass.should_receive(:new).
          with(anything, anything, anything, reflection.active_record)
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "removes the polymorphic setting from the options" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        reflection_klass.should_receive(:new) do |name, scope, options, parent|
          options[:polymorphic].should be_nil
        end
      else
        reflection_klass.should_receive(:new) do |macro, name, options, parent|
          options[:polymorphic].should be_nil
        end
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "adds the class name option" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        reflection_klass.should_receive(:new) do |name, scope, options, parent|
          options[:class_name].should == 'Bar'
        end
      else
        reflection_klass.should_receive(:new) do |macro, name, options, parent|
          options[:class_name].should == 'Bar'
        end
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "sets the foreign key if necessary" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        reflection_klass.should_receive(:new) do |name, scope, options, parent|
          options[:foreign_key].should == 'baz_id'
        end
      else
        reflection_klass.should_receive(:new) do |macro, name, options, parent|
          options[:foreign_key].should == 'baz_id'
        end
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "respects supplied foreign keys" do
      options[:foreign_key] = 'qux_id'

      if defined?(ActiveRecord::Reflection::MacroReflection)
        reflection_klass.should_receive(:new) do |name, scope, options, parent|
          options[:foreign_key].should == 'qux_id'
        end
      else
        reflection_klass.should_receive(:new) do |macro, name, options, parent|
          options[:foreign_key].should == 'qux_id'
        end
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "sets conditions if there are none" do
      reflection_klass.should_receive(:new) do |macro, name, options, parent|
        options[:conditions].should == "::ts_join_alias::.\"foo_type\" = 'Bar'"
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "appends to the conditions array" do
      options[:conditions] = ['existing']

      reflection_klass.should_receive(:new) do |macro, name, options, parent|
        options[:conditions].should == ['existing', "::ts_join_alias::.\"foo_type\" = 'Bar'"]
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "extends the conditions hash" do
      options[:conditions] = {:x => :y}

      reflection_klass.should_receive(:new) do |macro, name, options, parent|
        options[:conditions].should == {:x => :y, :foo_type => 'Bar'}
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "appends to the conditions string" do
      options[:conditions] = 'existing'

      reflection_klass.should_receive(:new) do |macro, name, options, parent|
        options[:conditions].should == "existing AND ::ts_join_alias::.\"foo_type\" = 'Bar'"
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "returns the new reflection" do
      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      ).should == filtered_reflection
    end
  end
end
