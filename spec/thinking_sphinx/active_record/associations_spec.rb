require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Associations do
  describe '#alias_for' do
    it "returns the model's table name when no stack is given" do
      pending
    end

    it "adds just one join for a stack with a single association" do
      pending
    end

    it "adds two joins for a stack with two associations" do
      pending
    end

    it "does not duplicate joins when given the same stack twice" do
      pending
    end

    it "extends upon existing joins when given stacks where parts are already mapped" do
      pending
    end
  end

  describe '#join_values' do
    it "returns all joins that have been created" do
      pending
    end
  end
end
