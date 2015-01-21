module ThinkingSphinx; end

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/delegation'
require 'thinking_sphinx/index_set'

describe ThinkingSphinx::IndexSet do
  let(:set)           { ThinkingSphinx::IndexSet.new options, configuration }
  let(:configuration) { double('configuration', :preload_indices => true,
    :indices => []) }
  let(:ar_base)       { double('ActiveRecord::Base') }
  let(:options)       { {} }

  before :each do
    stub_const 'ActiveRecord::Base', ar_base
  end

  def class_double(name, *superclasses)
    klass = double 'class', :name => name, :class => Class
    klass.stub :ancestors => ([klass] + superclasses + [ar_base])
    klass
  end

  describe '#to_a' do
    it "ensures the indices are loaded" do
      configuration.should_receive(:preload_indices)

      set.to_a
    end

    it "returns all non-distributed indices when no models or indices are specified" do
      article_core = double 'index', :name => 'article_core',
        :distributed? => false
      user_core    = double 'index', :name => 'user_core',
        :distributed? => false
      distributed  = double 'index', :name => 'user', :distributed? => true

      configuration.indices.replace [article_core, user_core, distributed]

      set.to_a.should == [article_core, user_core]
    end

    it "uses indices for the given classes" do
      configuration.indices.replace [
        double(:reference => :article,         :distributed? => false),
        double(:reference => :opinion_article, :distributed? => false),
        double(:reference => :page,            :distributed? => false)
      ]

      options[:classes] = [class_double('Article')]

      set.to_a.length.should == 1
    end

    it "requests indices for any superclasses" do
      configuration.indices.replace [
        double(:reference => :article,         :distributed? => false),
        double(:reference => :opinion_article, :distributed? => false),
        double(:reference => :page,            :distributed? => false)
      ]

      options[:classes] = [
        class_double('OpinionArticle', class_double('Article'))
      ]

      set.to_a.length.should == 2
    end

    it "uses named indices if names are provided" do
      article_core = double('index', :name => 'article_core')
      user_core    = double('index', :name => 'user_core')
      configuration.indices.replace [article_core, user_core]

      options[:indices] = ['article_core']

      set.to_a.should == [article_core]
    end

    it "selects from the full index set those with matching references" do
      configuration.indices.replace [
        double('index', :reference => :article, :distributed? => false),
        double('index', :reference => :book,    :distributed? => false),
        double('index', :reference => :page,    :distributed? => false)
      ]

      options[:references] = [:book, :article]

      set.to_a.length.should == 2
    end
  end
end
