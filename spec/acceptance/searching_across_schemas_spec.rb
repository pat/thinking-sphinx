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
    Product.search('Jekyll', :retry_stale => false).to_a.should == [jekyll]
    Product.search(:retry_stale => false).to_a.should == [jekyll]

    multi_schema.switch :thinking_sphinx
    hyde = Product.create name: 'Mister Hyde'
    Product.search('Jekyll', :retry_stale => false).to_a.should == []
    Product.search('Hyde', :retry_stale => false).to_a.should == [hyde]
    Product.search(:retry_stale => false).to_a.should == [hyde]

    multi_schema.switch :public
    Product.search('Jekyll', :retry_stale => false).to_a.should == [jekyll]
    Product.search(:retry_stale => false).to_a.should == [jekyll]
    Product.search('Hyde', :retry_stale => false).to_a.should == []

    Product.search(
      :middleware => ThinkingSphinx::Middlewares::RAW_ONLY,
      :indices    => ['product_core', 'product_two_core']
    ).to_a.length.should == 2
  end
end if multi_schema.active?
