require 'spec_helper'

describe ThinkingSphinx::Search::Translator do
  let(:translator) { ThinkingSphinx::Search::Translator.new raw }
  let(:raw)        { [] }
  let(:model)      { double('model') }

  describe '#to_active_record' do
    it "translates records to ActiveRecord objects" do
      model_name = double('article', :constantize => model)
      instance   = double('instance', :id => 24)
      model.stub!(:find => [instance])

      raw << {'sphinx_internal_id' => 24, 'sphinx_internal_class' => model_name}

      translator.to_active_record.should == [instance]
    end

    it "only queries the model once for the given search results" do
      model_name = double('article', :constantize => model)
      instance   = double('instance', :id => 24)
      raw << {'sphinx_internal_id' => 24, 'sphinx_internal_class' => model_name}
      raw << {'sphinx_internal_id' => 42, 'sphinx_internal_class' => model_name}

      model.should_receive(:find).once.and_return([instance])

      translator.to_active_record
    end

    it "handles multiple models" do
      article_model = double('article model')
      article_name  = double('article name', :constantize => article_model)
      article       = double('article instance', :id => 24)

      user_model    = double('user model')
      user_name     = double('user name', :constantize => user_model)
      user          = double('user instance', :id => 12)

      raw << {'sphinx_internal_id' => 24, 'sphinx_internal_class' => article_name}
      raw << {'sphinx_internal_id' => 12, 'sphinx_internal_class' => user_name}

      article_model.should_receive(:find).once.and_return([article])
      user_model.should_receive(:find).once.and_return([user])

      translator.to_active_record
    end

    it "sorts the results according to Sphinx order, not database order" do
      model_name = double('article', :constantize => model)
      instance_1 = double('instance 1', :id => 1)
      instance_2 = double('instance 1', :id => 2)

      raw << {'sphinx_internal_id' => 2, 'sphinx_internal_class' => model_name}
      raw << {'sphinx_internal_id' => 1, 'sphinx_internal_class' => model_name}

      model.stub(:find => [instance_1, instance_2])

      translator.to_active_record.should == [instance_2, instance_1]
    end
  end
end
