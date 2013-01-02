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

  context "multiple source definitions" do
    before :each do
      index.definition_block = Proc.new {
        define_source do
          indexes title
        end

        define_source do
          indexes title, content
        end
      }
      index.render
    end

    it "stores each source definition" do
      index.sources.length.should == 2
    end

    it "treats each source as separate" do
      index.sources.first.fields.length.should == 2
      index.sources.last.fields.length.should  == 3
    end
  end

  context 'wordcount fields and attributes' do
    before :each do
      index.definition_block = Proc.new {
        indexes title, :wordcount => true

        has content, :type => :wordcount
      }
      index.render
    end

    it "declares wordcount fields" do
      index.sources.first.sql_field_str2wordcount.should == ['title']
    end

    it "declares wordcount attributes" do
      index.sources.first.sql_attr_str2wordcount.should == ['content']
    end
  end

  context 'respecting source options' do
    before :each do
      index.definition_block = Proc.new {
        indexes title

        set_property :sql_range_step => 5
        set_property :disable_range? => true
      }
      index.render
    end

    it "allows for core source settings" do
      index.sources.first.sql_range_step.should == 5
    end

    it "allows for source options" do
      index.sources.first.disable_range?.should be_true
    end
  end
end
