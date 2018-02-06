# frozen_string_literal: true

module ThinkingSphinx
  module Middlewares; end
  class  Search; end
end

require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/active_record_translator'
require 'thinking_sphinx/search/stale_ids_exception'

describe ThinkingSphinx::Middlewares::ActiveRecordTranslator do
  let(:app)        { double('app', :call => true) }
  let(:middleware) {
    ThinkingSphinx::Middlewares::ActiveRecordTranslator.new app }
  let(:context)    { {:raw => [], :results => [] } }
  let(:model)      { double('model', :primary_key => :id) }
  let(:search)     { double('search', :options => {}) }
  let(:configuration) { double('configuration', :settings => {:primary_key => :id}) }

  def raw_result(id, model_name)
    {'sphinx_internal_id' => id, 'sphinx_internal_class' => model_name}
  end

  describe '#call' do
    before :each do
      allow(context).to receive_messages :search => search
      allow(context).to receive_messages :configuration => configuration
      allow(model).to receive_messages :unscoped => model
    end

    it "translates records to ActiveRecord objects" do
      model_name = double('article', :constantize => model)
      instance   = double('instance', :id => 24)
      allow(model).to receive_messages :where => [instance]

      context[:results] << raw_result(24, model_name)

      middleware.call [context]

      expect(context[:results]).to eq([instance])
    end

    it "only queries the model once for the given search results" do
      model_name = double('article', :constantize => model)
      instance_a = double('instance', :id => 24)
      instance_b = double('instance', :id => 42)
      context[:results] << raw_result(24, model_name)
      context[:results] << raw_result(42, model_name)

      expect(model).to receive(:where).once.and_return([instance_a, instance_b])

      middleware.call [context]
    end

    it "handles multiple models" do
      article_model = double('article model', :primary_key => :id)
      article_name  = double('article name', :constantize => article_model)
      article       = double('article instance', :id => 24)

      user_model    = double('user model', :primary_key => :id)
      user_name     = double('user name', :constantize => user_model)
      user          = double('user instance', :id => 12)

      allow(article_model).to receive_messages :unscoped => article_model
      allow(user_model).to receive_messages :unscoped => user_model

      context[:results] << raw_result(24, article_name)
      context[:results] << raw_result(12, user_name)

      expect(article_model).to receive(:where).once.and_return([article])
      expect(user_model).to receive(:where).once.and_return([user])

      middleware.call [context]
    end

    it "sorts the results according to Sphinx order, not database order" do
      model_name = double('article', :constantize => model)
      instance_1 = double('instance 1', :id => 1)
      instance_2 = double('instance 2', :id => 2)

      context[:results] << raw_result(2, model_name)
      context[:results] << raw_result(1, model_name)

      allow(model).to receive_messages(:where => [instance_1, instance_2])

      middleware.call [context]

      expect(context[:results]).to eq([instance_2, instance_1])
    end

    it "returns objects in database order if a SQL order clause is supplied" do
      model_name = double('article', :constantize => model)
      instance_1 = double('instance 1', :id => 1)
      instance_2 = double('instance 2', :id => 2)

      context[:results] << raw_result(2, model_name)
      context[:results] << raw_result(1, model_name)

      allow(model).to receive_messages(:order => model, :where => [instance_1, instance_2])
      search.options[:sql] = {:order => 'name DESC'}

      middleware.call [context]

      expect(context[:results]).to eq([instance_1, instance_2])
    end

    it "handles model without primary key" do
      no_primary_key_model = double('no primary key model')
      allow(no_primary_key_model).to receive_messages :unscoped => no_primary_key_model
      model_name = double('article', :constantize => no_primary_key_model)
      instance   = double('instance', :id => 1)
      allow(no_primary_key_model).to receive_messages :where => [instance]

      context[:results] << raw_result(1, model_name)

      middleware.call [context]
    end

    context 'SQL options' do
      let(:relation) { double('relation', :where => []) }

      before :each do
        allow(model).to receive_messages :unscoped => relation

        model_name = double('article', :constantize => model)
        context[:results] << raw_result(1, model_name)
      end

      it "passes through SQL include options to the relation" do
        search.options[:sql] = {:include => :association}

        expect(relation).to receive(:includes).with(:association).
          and_return(relation)

        middleware.call [context]
      end

      it "passes through SQL join options to the relation" do
        search.options[:sql] = {:joins => :association}

        expect(relation).to receive(:joins).with(:association).and_return(relation)

        middleware.call [context]
      end

      it "passes through SQL order options to the relation" do
        search.options[:sql] = {:order => 'name DESC'}

        expect(relation).to receive(:order).with('name DESC').and_return(relation)

        middleware.call [context]
      end

      it "passes through SQL select options to the relation" do
        search.options[:sql] = {:select => :column}

        expect(relation).to receive(:select).with(:column).and_return(relation)

        middleware.call [context]
      end

      it "passes through SQL group options to the relation" do
        search.options[:sql] = {:group => :column}

        expect(relation).to receive(:group).with(:column).and_return(relation)

        middleware.call [context]
      end

      it "passes through SQL where options to the relation" do
        search.options[:sql] = {:where => "deleted_at IS NULL"}

        expect(relation).to receive(:where).with("deleted_at IS NULL").and_return(relation)

        middleware.call [context]
      end

    end
  end
end
