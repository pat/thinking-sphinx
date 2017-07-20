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

    real_time_index = ThinkingSphinx::RealTime::Index.new(:product)
    real_time_index.definition_block = Proc.new {
      indexes name
    }

    ThinkingSphinx::Configuration::ConsistentIds.new(
      [small_index, large_index, real_time_index]
    ).reconcile

    expect(large_index.sources.first.attributes.detect { |attribute|
      attribute.name == 'sphinx_internal_id'
    }.type).to eq(:bigint)

    expect(small_index.sources.first.attributes.detect { |attribute|
      attribute.name == 'sphinx_internal_id'
    }.type).to eq(:bigint)

    expect(real_time_index.attributes.detect { |attribute|
      attribute.name == 'sphinx_internal_id'
    }.type).to eq(:bigint)
  end
end

describe '64 bit document ids', :live => true do
  context 'with ActiveRecord' do
    it 'handles large 32 bit integers with an offset multiplier' do
      user = User.create! :name => 'Pat'
      user.update_column :id, 980190962

      index

      expect(User.search('pat').to_a).to eq([user])
    end
  end

  context 'with Real-Time' do
    it 'handles large 32 bit integers with an offset multiplier' do
      product = Product.create! :name => "Widget"
      product.update_attributes :id => 980190962
      expect(
        Product.search('widget', :indices => ['product_core']).to_a
      ).to eq([product])
    end
  end
end if `searchd --help`.split("\n")[0][/id64/]
