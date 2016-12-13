require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::FilterReflection do
  describe '.call' do
    let(:reflection) { double('Reflection', :macro => :has_some,
      :options => options, :active_record => double, :name => 'baz',
      :foreign_type => :foo_type, :class => reflection_klass) }
    let(:options)    { {:polymorphic => true} }
    let(:filtered_reflection) { double 'filtered reflection' }
    let(:reflection_klass)    { double :new => filtered_reflection,
      :instance_method => initialize_method }
    let(:initialize_method)   { double :arity => 4 }

    before :each do
      allow(reflection.active_record).to receive_message_chain(:connection, :quote_column_name).
        and_return('"foo_type"')
    end

    it "uses the existing reflection's macro" do
      expect(reflection_klass).to receive(:new).
        with(:has_some, anything, anything, anything)

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "uses the supplied name" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        expect(reflection_klass).to receive(:new).
          with('foo_bar', anything, anything, anything)
      else
        expect(reflection_klass).to receive(:new).
          with(anything, 'foo_bar', anything, anything)
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "uses the existing reflection's parent" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        expect(reflection_klass).to receive(:new).
          with(anything, anything, anything, reflection.active_record)
      else
        expect(reflection_klass).to receive(:new).
          with(anything, anything, anything, reflection.active_record)
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "removes the polymorphic setting from the options" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        expect(reflection_klass).to receive(:new) do |name, scope, options, parent|
          expect(options[:polymorphic]).to be_nil
        end
      else
        expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
          expect(options[:polymorphic]).to be_nil
        end
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "adds the class name option" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        expect(reflection_klass).to receive(:new) do |name, scope, options, parent|
          expect(options[:class_name]).to eq('Bar')
        end
      else
        expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
          expect(options[:class_name]).to eq('Bar')
        end
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "sets the foreign key if necessary" do
      if defined?(ActiveRecord::Reflection::MacroReflection)
        expect(reflection_klass).to receive(:new) do |name, scope, options, parent|
          expect(options[:foreign_key]).to eq('baz_id')
        end
      else
        expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
          expect(options[:foreign_key]).to eq('baz_id')
        end
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "respects supplied foreign keys" do
      options[:foreign_key] = 'qux_id'

      if defined?(ActiveRecord::Reflection::MacroReflection)
        expect(reflection_klass).to receive(:new) do |name, scope, options, parent|
          expect(options[:foreign_key]).to eq('qux_id')
        end
      else
        expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
          expect(options[:foreign_key]).to eq('qux_id')
        end
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "sets conditions if there are none" do
      expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
        expect(options[:conditions]).to eq("::ts_join_alias::.\"foo_type\" = 'Bar'")
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "appends to the conditions array" do
      options[:conditions] = ['existing']

      expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
        expect(options[:conditions]).to eq(['existing', "::ts_join_alias::.\"foo_type\" = 'Bar'"])
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "extends the conditions hash" do
      options[:conditions] = {:x => :y}

      expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
        expect(options[:conditions]).to eq({:x => :y, :foo_type => 'Bar'})
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "appends to the conditions string" do
      options[:conditions] = 'existing'

      expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
        expect(options[:conditions]).to eq("existing AND ::ts_join_alias::.\"foo_type\" = 'Bar'")
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end unless defined?(ActiveRecord::Reflection::MacroReflection)

    it "returns the new reflection" do
      expect(ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )).to eq(filtered_reflection)
    end
  end
end
