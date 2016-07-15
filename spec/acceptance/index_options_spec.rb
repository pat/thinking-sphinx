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
        expect(index.send("#{type}_fields")).to be_nil
      end

      it "sets min_#{type}_len" do
        expect(index.send("min_#{type}_len")).to eq(3)
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
        expect(index.send("#{type}_fields")).to eq('title')
      end

      it "sets min_#{type}_len" do
        expect(index.send("min_#{type}_len")).to eq(3)
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
      expect(index.sources.length).to eq(2)
    end

    it "treats each source as separate" do
      expect(index.sources.first.fields.length).to eq(2)
      expect(index.sources.last.fields.length).to  eq(3)
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
      expect(index.sources.first.sql_field_str2wordcount).to eq(['title'])
    end

    it "declares wordcount attributes" do
      expect(index.sources.first.sql_attr_str2wordcount).to eq(['content'])
    end
  end

  context 'respecting source options' do
    before :each do
      index.definition_block = Proc.new {
        indexes title

        set_property :sql_range_step => 5
        set_property :disable_range? => true
        set_property :sql_query_pre => ["DO STUFF"]
      }
      index.render
    end

    it "allows for core source settings" do
      expect(index.sources.first.sql_range_step).to eq(5)
    end

    it "allows for source options" do
      expect(index.sources.first.disable_range?).to be_truthy
    end

    it "respects sql_query_pre values" do
      expect(index.sources.first.sql_query_pre).to include("DO STUFF")
    end
  end

  context 'respecting index options over core configuration' do
    before :each do
      ThinkingSphinx::Configuration.instance.settings['min_infix_len'] = 2
      ThinkingSphinx::Configuration.instance.settings['sql_range_step'] = 2

      index.definition_block = Proc.new {
        indexes title

        set_property :min_infix_len => 1
        set_property :sql_range_step => 20
      }
      index.render
    end

    after :each do
      ThinkingSphinx::Configuration.instance.settings.delete 'min_infix_len'
      ThinkingSphinx::Configuration.instance.settings.delete 'sql_range_step'
    end

    it "prioritises index-level options over YAML options" do
      expect(index.min_infix_len).to eq(1)
    end

    it "prioritises index-level source options" do
      expect(index.sources.first.sql_range_step).to eq(20)
    end

    it "keeps index-level options prioritised when rendered again" do
      index.render

      expect(index.min_infix_len).to eq(1)
    end

    it "keeps index-level options prioritised when rendered again" do
      index.render

      expect(index.sources.first.sql_range_step).to eq(20)
    end
  end
end
