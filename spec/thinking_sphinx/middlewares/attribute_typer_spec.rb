require 'spec_helper'

RSpec.describe ThinkingSphinx::Middlewares::AttributeTyper do
  let(:app)        { double('app', :call => true) }
  let(:middleware) { ThinkingSphinx::Middlewares::AttributeTyper.new app }
  let(:attributes) { {} }
  let(:context)    { double('context', :search => search) }
  let(:search)     { double('search', :options => {}) }

  before :each do
    allow(ThinkingSphinx::AttributeTypes).to receive(:call).
      and_return(attributes)
    allow(ActiveSupport::Deprecation).to receive(:warn)
  end

  it 'warns when providing a string value for an integer attribute' do
    attributes['user_id'] = [:uint]
    search.options[:with] = {:user_id => '1'}

    expect(ActiveSupport::Deprecation).to receive(:warn)

    middleware.call [context]
  end

  it 'warns when providing a string value for a float attribute' do
    attributes['price'] = [:float]
    search.options[:without] = {:price => '1.0'}

    expect(ActiveSupport::Deprecation).to receive(:warn)

    middleware.call [context]
  end

  it 'proceeds when providing a string value for a string attribute' do
    attributes['status'] = [:string]
    search.options[:with] = {:status => 'completed'}

    expect(ActiveSupport::Deprecation).not_to receive(:warn)

    middleware.call [context]
  end
end
