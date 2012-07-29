require 'acceptance/spec_helper'

describe '64 bit integer support' do
  it "ensures all internal id attributes are big ints if one is" do
    large_index = ThinkingSphinx::ActiveRecord::Index.new(:tweet)
    large_index.definition_block = Proc.new {
      indexes text
    }

    small_index = ThinkingSphinx::ActiveRecord::Index.new(:article)
    small_index.definition_block = Proc.new {
      indexes title
    }

    ThinkingSphinx::Configuration::ConsistentIds.new(
      [small_index, large_index]
    ).reconcile

    large_index.sources.first.attributes.detect { |attribute|
      attribute.name == 'sphinx_internal_id'
    }.type.should == :bigint

    small_index.sources.first.attributes.detect { |attribute|
      attribute.name == 'sphinx_internal_id'
    }.type.should == :bigint
  end
end
