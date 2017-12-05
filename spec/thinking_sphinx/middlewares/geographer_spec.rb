# frozen_string_literal: true

module ThinkingSphinx
  module Middlewares; end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/geographer'
require 'thinking_sphinx/float_formatter'

describe ThinkingSphinx::Middlewares::Geographer do
  let(:app)        { double('app', :call => true) }
  let(:middleware) { ThinkingSphinx::Middlewares::Geographer.new app }
  let(:context)    { {:sphinxql => sphinx_sql, :indices => [], :panes => []} }
  let(:sphinx_sql) { double('sphinx_sql') }
  let(:search)     { double('search', :options => {}) }

  before :each do
    stub_const 'ThinkingSphinx::Panes::DistancePane', double

    allow(context).to receive_messages :search => search
  end

  describe '#call' do
    context 'no geodistance location provided' do
      before :each do
        search.options[:geo] = nil
      end

      it "doesn't add anything if :geo is nil" do
        expect(sphinx_sql).not_to receive(:prepend_values)

        middleware.call [context]
      end
    end

    context 'geodistance location provided' do
      before :each do
        search.options[:geo] = [0.1, 0.2]
      end

      it "adds the geodist function when given a :geo option" do
        expect(sphinx_sql).to receive(:prepend_values).
          with('GEODIST(0.1, 0.2, lat, lng) AS geodist').
          and_return(sphinx_sql)

        middleware.call [context]
      end

      it "adds the distance pane" do
        allow(sphinx_sql).to receive_messages :prepend_values => sphinx_sql

        middleware.call [context]

        expect(context[:panes]).to include(ThinkingSphinx::Panes::DistancePane)
      end

      it "respects :latitude_attr and :longitude_attr options" do
        search.options[:latitude_attr]  = 'side_to_side'
        search.options[:longitude_attr] = 'up_or_down'

        expect(sphinx_sql).to receive(:prepend_values).
          with('GEODIST(0.1, 0.2, side_to_side, up_or_down) AS geodist').
          and_return(sphinx_sql)

        middleware.call [context]
      end

      it "uses latitude if any index has that but not lat as an attribute" do
        context[:indices] << double('index',
          :unique_attribute_names => ['latitude'], :name => 'an_index')

        expect(sphinx_sql).to receive(:prepend_values).
          with('GEODIST(0.1, 0.2, latitude, lng) AS geodist').
          and_return(sphinx_sql)

        middleware.call [context]
      end

      it "uses latitude if any index has that but not lat as an attribute" do
        context[:indices] << double('index',
          :unique_attribute_names => ['longitude'], :name => 'an_index')

        expect(sphinx_sql).to receive(:prepend_values).
          with('GEODIST(0.1, 0.2, lat, longitude) AS geodist').
          and_return(sphinx_sql)

        middleware.call [context]
      end

      it "handles very small values" do
        search.options[:geo] = [0.0000001, 0.00000000002]

        expect(sphinx_sql).to receive(:prepend_values).
          with('GEODIST(0.0000001, 0.00000000002, lat, lng) AS geodist').
          and_return(sphinx_sql)

        middleware.call [context]
      end
    end
  end
end
