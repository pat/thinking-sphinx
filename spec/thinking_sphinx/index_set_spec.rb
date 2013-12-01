module ThinkingSphinx; end

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/delegation'
require 'thinking_sphinx/index_set'

describe ThinkingSphinx::IndexSet do
  let(:set)           { ThinkingSphinx::IndexSet.new classes, indices,
    configuration }
  let(:classes)       { [] }
  let(:indices)       { [] }
  let(:configuration) { double('configuration', :preload_indices => true,
    :indices => []) }
  let(:ar_base)       { double('ActiveRecord::Base') }

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
      classes << class_double('Article')

      configuration.should_receive(:indices_for_references).with(:article).
        and_return([])

      set.to_a
    end

    it "requests indices for any superclasses" do
      classes << class_double('OpinionArticle', class_double('Article'))

      configuration.should_receive(:indices_for_references).
        with(:opinion_article, :article).and_return([])

      set.to_a
    end

    it "uses named indices if names are provided" do
      article_core = double('index', :name => 'article_core')
      user_core    = double('index', :name => 'user_core')
      configuration.indices.replace [article_core, user_core]

      indices << 'article_core'

      set.to_a.should == [article_core]
    end
  end
end
