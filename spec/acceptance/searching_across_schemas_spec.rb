require 'acceptance/spec_helper'

multi_schema = MultiSchema.new

describe 'Searching across PostgreSQL schemas', :live => true do
  before :each do
    ThinkingSphinx::Configuration.instance.index_set_class =
      MultiSchema::IndexSet
  end

  after :each do
    ThinkingSphinx::Configuration.instance.index_set_class = nil
    multi_schema.switch :public
  end

  it 'can distinguish between objects with the same primary key' do
    multi_schema.switch :public
    jekyll = Product.create name: 'Doctor Jekyll'
    expect(Product.search('Jekyll', :retry_stale => false).to_a).to eq([jekyll])
    expect(Product.search(:retry_stale => false).to_a).to eq([jekyll])

    multi_schema.switch :thinking_sphinx
    hyde = Product.create name: 'Mister Hyde'
    expect(Product.search('Jekyll', :retry_stale => false).to_a).to eq([])
    expect(Product.search('Hyde', :retry_stale => false).to_a).to eq([hyde])
    expect(Product.search(:retry_stale => false).to_a).to eq([hyde])

    multi_schema.switch :public
    expect(Product.search('Jekyll', :retry_stale => false).to_a).to eq([jekyll])
    expect(Product.search(:retry_stale => false).to_a).to eq([jekyll])
    expect(Product.search('Hyde', :retry_stale => false).to_a).to eq([])

    expect(Product.search(
      :middleware => ThinkingSphinx::Middlewares::RAW_ONLY,
      :indices    => ['product_core', 'product_two_core']
    ).to_a.length).to eq(2)
  end
end if multi_schema.active?
