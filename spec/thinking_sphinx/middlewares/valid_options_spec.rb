require 'spec_helper'

RSpec.describe ThinkingSphinx::Middlewares::ValidOptions do
  let(:app)        { double 'app', :call => true }
  let(:middleware) { ThinkingSphinx::Middlewares::ValidOptions.new app }
  let(:context)    { double 'context', :search => search }
  let(:search)     { double 'search', :options => {} }

  before :each do
    allow(ThinkingSphinx::Logger).to receive(:log)
  end

  context 'with unknown options' do
    before :each do
      search.options[:foo] = :bar
    end

    it "adds a warning" do
      expect(ThinkingSphinx::Logger).to receive(:log).
        with(:warn, "Unexpected search options: [:foo]")

      middleware.call [context]
    end

    it 'continues on' do
      expect(app).to receive(:call).with([context])

      middleware.call [context]
    end
  end

  context "with known options" do
    before :each do
      search.options[:ids_only] = true
    end

    it "is silent" do
      expect(ThinkingSphinx::Logger).to_not receive(:log)

      middleware.call [context]
    end

    it 'continues on' do
      expect(app).to receive(:call).with([context])

      middleware.call [context]
    end
  end
end
