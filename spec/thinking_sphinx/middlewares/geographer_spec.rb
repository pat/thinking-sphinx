module ThinkingSphinx
  module Middlewares; end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/geographer'

describe ThinkingSphinx::Middlewares::Geographer do
  let(:app)        { double('app', :call => true) }
  let(:middleware) { ThinkingSphinx::Middlewares::Geographer.new app }
  let(:context)    { {:sphinxql => sphinx_sql, :indices => []} }
  let(:sphinx_sql) { double('sphinx_sql') }
  let(:search)     { double('search', :options => {}) }

  before :each do
    context.stub :search => search
  end

  describe '#call' do
    it "adds the geodist function when given a :geo option" do
      search.options[:geo] = [0.1, 0.2]

      sphinx_sql.should_receive(:values).
        with('GEODIST(0.1, 0.2, lat, lng) AS geodist').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "doesn't add anything if :geo is nil" do
      search.options[:geo] = nil

      sphinx_sql.should_not_receive(:values)

      middleware.call [context]
    end

    it "respects :latitude_attr and :longitude_attr options" do
      search.options[:latitude_attr]  = 'side_to_side'
      search.options[:longitude_attr] = 'up_or_down'
      search.options[:geo] = [0.1, 0.2]

      sphinx_sql.should_receive(:values).
        with('GEODIST(0.1, 0.2, side_to_side, up_or_down) AS geodist').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses latitude if any index has that but not lat as an attribute" do
      context[:indices] << double('index',
        :unique_attribute_names => ['latitude'], :name => 'an_index')
      search.options[:geo] = [0.1, 0.2]

      sphinx_sql.should_receive(:values).
        with('GEODIST(0.1, 0.2, latitude, lng) AS geodist').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses latitude if any index has that but not lat as an attribute" do
      context[:indices] << double('index',
        :unique_attribute_names => ['longitude'], :name => 'an_index')
      search.options[:geo] = [0.1, 0.2]

      sphinx_sql.should_receive(:values).
        with('GEODIST(0.1, 0.2, lat, longitude) AS geodist').
        and_return(sphinx_sql)

      middleware.call [context]
    end
  end
end
