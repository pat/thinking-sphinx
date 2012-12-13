require 'acceptance/spec_helper'

describe 'Index options' do
  let(:index) { ThinkingSphinx::ActiveRecord::Index.new(:article) }

  %w( infix prefix ).each do |type|
    context "all fields are #{type}ed" do
      before :each do
        index.definition_block = Proc.new {
          indexes title
          set_property "min_#{type}_len".to_sym => 3
        }
        index.render
      end

      it "keeps #{type}_fields blank" do
        index.send("#{type}_fields").should be_nil
      end

      it "sets min_#{type}_len" do
        index.send("min_#{type}_len").should == 3
      end
    end

    context "some fields are #{type}ed" do
      before :each do
        index.definition_block = Proc.new {
          indexes title, "#{type}es".to_sym => true
          indexes content
          set_property "min_#{type}_len".to_sym => 3
        }
        index.render
      end

      it "#{type}_fields should contain the field" do
        index.send("#{type}_fields").should == 'title'
      end

      it "sets min_#{type}_len" do
        index.send("min_#{type}_len").should == 3
      end
    end
  end
end
