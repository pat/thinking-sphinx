require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Column do
  describe '#__name' do
    it "returns the top item" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:content)
      column.__name.should == :content
    end
  end

  describe '#__replace' do
    let(:base)         { [:a, :b] }
    let(:replacements) { [[:a, :c], [:a, :d]] }

    it "returns itself when it's a string column" do
      column = ThinkingSphinx::ActiveRecord::Column.new('foo')
      column.__replace(base, replacements).collect(&:__path).
        should == [['foo']]
    end

    it "returns itself when the base of the stack does not match" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:b, :c)
      column.__replace(base, replacements).collect(&:__path).
        should == [[:b, :c]]
    end

    it "returns an array of new columns " do
      column = ThinkingSphinx::ActiveRecord::Column.new(:a, :b, :e)
      column.__replace(base, replacements).collect(&:__path).
        should == [[:a, :c, :e], [:a, :d, :e]]
    end
  end

  describe '#__stack' do
    it "returns all but the top item" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:users, :posts, :id)
      column.__stack.should == [:users, :posts]
    end
  end

  describe '#method_missing' do
    let(:column) { ThinkingSphinx::ActiveRecord::Column.new(:user) }

    it "shifts the current name to the stack" do
      column.email
      column.__stack.should == [:user]
    end

    it "adds the new method call as the name" do
      column.email
      column.__name.should == :email
    end

    it "returns itself" do
      column.email.should == column
    end
  end

  describe '#string?' do
    it "is true when the name is a string" do
      column = ThinkingSphinx::ActiveRecord::Column.new('content')
      column.should be_a_string
    end

    it "is false when the name is a symbol" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:content)
      column.should_not be_a_string
    end
  end
end
