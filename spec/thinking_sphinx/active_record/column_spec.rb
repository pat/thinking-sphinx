# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Column do
  describe '#__name' do
    it "returns the top item" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:content)
      expect(column.__name).to eq(:content)
    end
  end

  describe '#__replace' do
    let(:base)         { [:a, :b] }
    let(:replacements) { [[:a, :c], [:a, :d]] }

    it "returns itself when it's a string column" do
      column = ThinkingSphinx::ActiveRecord::Column.new('foo')
      expect(column.__replace(base, replacements).collect(&:__path)).
        to eq([['foo']])
    end

    it "returns itself when the base of the stack does not match" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:b, :c)
      expect(column.__replace(base, replacements).collect(&:__path)).
        to eq([[:b, :c]])
    end

    it "returns an array of new columns " do
      column = ThinkingSphinx::ActiveRecord::Column.new(:a, :b, :e)
      expect(column.__replace(base, replacements).collect(&:__path)).
        to eq([[:a, :c, :e], [:a, :d, :e]])
    end
  end

  describe '#__stack' do
    it "returns all but the top item" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:users, :posts, :id)
      expect(column.__stack).to eq([:users, :posts])
    end
  end

  describe '#method_missing' do
    let(:column) { ThinkingSphinx::ActiveRecord::Column.new(:user) }

    it "shifts the current name to the stack" do
      column.email
      expect(column.__stack).to eq([:user])
    end

    it "adds the new method call as the name" do
      column.email
      expect(column.__name).to eq(:email)
    end

    it "returns itself" do
      expect(column.email).to eq(column)
    end
  end

  describe '#string?' do
    it "is true when the name is a string" do
      column = ThinkingSphinx::ActiveRecord::Column.new('content')
      expect(column).to be_a_string
    end

    it "is false when the name is a symbol" do
      column = ThinkingSphinx::ActiveRecord::Column.new(:content)
      expect(column).not_to be_a_string
    end
  end
end
