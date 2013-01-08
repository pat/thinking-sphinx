require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Polymorpher do
  let(:polymorpher) { ThinkingSphinx::ActiveRecord::Polymorpher.new source,
    column, class_names }
  let(:source)      { double 'Source', :model => outer, :fields => [field],
    :attributes => [attribute] }
  let(:column)      { double 'Column', :__name => :foo, :__stack => [:a, :b],
    :__path => [:a, :b, :foo] }
  let(:class_names) { %w( Article Animal ) }
  let(:field)       { double :rebase => true }
  let(:attribute)   { double :rebase => true }
  let(:outer)       { double :reflections => {:a => double(:klass => inner)} }
  let(:inner)       { double :reflections => {:b => double(:klass => model)} }
  let(:model)       { double 'Model', :reflections => {:foo => reflection} }
  let(:reflection)  { double 'Polymorphic Reflection' }

  describe '#morph!' do
    let(:article_reflection) { double 'Article Reflection' }
    let(:animal_reflection)  { double 'Animal Reflection' }

    before :each do
      ThinkingSphinx::ActiveRecord::FilteredReflection.
        stub(:clone_with_filter).
        and_return(article_reflection, animal_reflection)
    end

    it "creates a new reflection for each class" do
      ThinkingSphinx::ActiveRecord::FilteredReflection.
        unstub :clone_with_filter

      ThinkingSphinx::ActiveRecord::FilteredReflection.
        should_receive(:clone_with_filter).
        with(reflection, :foo_article, 'Article').
        and_return(article_reflection)
      ThinkingSphinx::ActiveRecord::FilteredReflection.
        should_receive(:clone_with_filter).
        with(reflection, :foo_animal, 'Animal').
        and_return(animal_reflection)

      polymorpher.morph!
    end

    it "adds the new reflections to the end-of-stack model" do
      polymorpher.morph!

      model.reflections[:foo_article].should == article_reflection
      model.reflections[:foo_animal].should  == animal_reflection
    end

    it "rebases each field" do
      field.should_receive(:rebase).with([:a, :b, :foo],
        :to => [[:a, :b, :foo_article], [:a, :b, :foo_animal]])

      polymorpher.morph!
    end

    it "rebases each attribute" do
      attribute.should_receive(:rebase).with([:a, :b, :foo],
        :to => [[:a, :b, :foo_article], [:a, :b, :foo_animal]])

      polymorpher.morph!
    end
  end
end
