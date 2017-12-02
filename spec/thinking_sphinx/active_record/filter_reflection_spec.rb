require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::FilterReflection do
  describe '.call' do
    let(:reflection) { double('Reflection', :macro => :has_some,
      :options => options, :active_record => double, :name => 'baz',
      :foreign_type => :foo_type, :class => original_klass) }
    let(:options)    { {:polymorphic => true} }
    let(:filtered_reflection) { double 'filtered reflection' }
    let(:original_klass)      { double }
    let(:subclass)            { double :include => true }

    before :each do
      allow(reflection.active_record).to receive_message_chain(:connection, :quote_column_name).
        and_return('"foo_type"')

      if ActiveRecord::VERSION::STRING.to_f < 5.2
        allow(original_klass).to receive(:new).and_return(filtered_reflection)
      else
        allow(Class).to receive(:new).with(original_klass).and_return(subclass)
        allow(subclass).to receive(:new).and_return(filtered_reflection)
      end
    end

    class ArgumentsWrapper
      attr_reader :macro, :name, :scope, :options, :parent

      def initialize(*arguments)
        if ActiveRecord::VERSION::STRING.to_f < 4.0
          @macro, @name, @options, @parent = arguments
        elsif ActiveRecord::VERSION::STRING.to_f < 4.2
          @macro, @name, @scope, @options, @parent = arguments
        else
          @name, @scope, @options, @parent = arguments
        end
      end
    end

    def reflection_klass
      ActiveRecord::VERSION::STRING.to_f < 5.2 ? original_klass : subclass
    end

    def expected_reflection_arguments
      expect(reflection_klass).to receive(:new) do |*arguments|
        yield ArgumentsWrapper.new(*arguments)
      end
    end

    it "uses the existing reflection's macro" do
      expect(reflection_klass).to receive(:new) do |macro, *args|
        expect(macro).to eq(:has_some)
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end if ActiveRecord::VERSION::STRING.to_f < 4.2

    it "uses the supplied name" do
      expected_reflection_arguments do |wrapper|
        expect(wrapper.name).to eq('foo_bar')
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "uses the existing reflection's parent" do
      expected_reflection_arguments do |wrapper|
        expect(wrapper.parent).to eq(reflection.active_record)
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "removes the polymorphic setting from the options" do
      expected_reflection_arguments do |wrapper|
        expect(wrapper.options[:polymorphic]).to be_nil
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "adds the class name option" do
      expected_reflection_arguments do |wrapper|
        expect(wrapper.options[:class_name]).to eq('Bar')
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "sets the foreign key if necessary" do
      expected_reflection_arguments do |wrapper|
        expect(wrapper.options[:foreign_key]).to eq('baz_id')
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    it "respects supplied foreign keys" do
      options[:foreign_key] = 'qux_id'

      expected_reflection_arguments do |wrapper|
        expect(wrapper.options[:foreign_key]).to eq('qux_id')
      end

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end

    if ActiveRecord::VERSION::STRING.to_f < 4.0
      it "sets conditions if there are none" do
        expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
          expect(options[:conditions]).to eq("::ts_join_alias::.\"foo_type\" = 'Bar'")
        end

        ThinkingSphinx::ActiveRecord::FilterReflection.call(
          reflection, 'foo_bar', 'Bar'
        )
      end

      it "appends to the conditions array" do
        options[:conditions] = ['existing']

        expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
          expect(options[:conditions]).to eq(['existing', "::ts_join_alias::.\"foo_type\" = 'Bar'"])
        end

        ThinkingSphinx::ActiveRecord::FilterReflection.call(
          reflection, 'foo_bar', 'Bar'
        )
      end

      it "extends the conditions hash" do
        options[:conditions] = {:x => :y}

        expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
          expect(options[:conditions]).to eq({:x => :y, :foo_type => 'Bar'})
        end

        ThinkingSphinx::ActiveRecord::FilterReflection.call(
          reflection, 'foo_bar', 'Bar'
        )
      end

      it "appends to the conditions string" do
        options[:conditions] = 'existing'

        expect(reflection_klass).to receive(:new) do |macro, name, options, parent|
          expect(options[:conditions]).to eq("existing AND ::ts_join_alias::.\"foo_type\" = 'Bar'")
        end

        ThinkingSphinx::ActiveRecord::FilterReflection.call(
          reflection, 'foo_bar', 'Bar'
        )
      end
    else
      it "does not add a conditions option" do
        expected_reflection_arguments do |wrapper|
          expect(wrapper.options.keys).not_to include(:conditions)
        end

        ThinkingSphinx::ActiveRecord::FilterReflection.call(
          reflection, 'foo_bar', 'Bar'
        )
      end
    end

    it "includes custom behaviour in the subclass" do
      expect(subclass).to receive(:include).with(ThinkingSphinx::ActiveRecord::Depolymorph::OverriddenReflection::JoinConstraint)

      ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )
    end if ActiveRecord::VERSION::STRING.to_f > 5.1

    it "returns the new reflection" do
      expect(ThinkingSphinx::ActiveRecord::FilterReflection.call(
        reflection, 'foo_bar', 'Bar'
      )).to eq(filtered_reflection)
    end
  end
end
