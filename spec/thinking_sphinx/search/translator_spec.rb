require 'spec_helper'

describe ThinkingSphinx::Search::Translator do
  let(:translator) { ThinkingSphinx::Search::Translator.new raw, excerpter }
  let(:raw)        { [] }
  let(:excerpter)  { double('excerpter') }
  let(:model)      { double('model') }

  def raw_result(id, model_name)
    {'sphinx_internal_id' => id, 'sphinx_internal_class_attr' => model_name}
  end

  describe '#to_active_record' do
    it "translates records to ActiveRecord objects" do
      model_name = double('article', :constantize => model)
      instance   = double('instance', :id => 24)
      model.stub!(:where => [instance])

      raw << raw_result(24, model_name)

      translator.to_active_record.should == [instance]
    end

    it "only queries the model once for the given search results" do
      model_name = double('article', :constantize => model)
      instance_a = double('instance', :id => 24)
      instance_b = double('instance', :id => 42)
      raw << raw_result(24, model_name)
      raw << raw_result(42, model_name)

      model.should_receive(:where).once.and_return([instance_a, instance_b])

      translator.to_active_record
    end

    it "handles multiple models" do
      article_model = double('article model')
      article_name  = double('article name', :constantize => article_model)
      article       = double('article instance', :id => 24)

      user_model    = double('user model')
      user_name     = double('user name', :constantize => user_model)
      user          = double('user instance', :id => 12)

      raw << raw_result(24, article_name)
      raw << raw_result(12, user_name)

      article_model.should_receive(:where).once.and_return([article])
      user_model.should_receive(:where).once.and_return([user])

      translator.to_active_record
    end

    it "sorts the results according to Sphinx order, not database order" do
      model_name = double('article', :constantize => model)
      instance_1 = double('instance 1', :id => 1)
      instance_2 = double('instance 1', :id => 2)

      raw << raw_result(2, model_name)
      raw << raw_result(1, model_name)

      model.stub(:where => [instance_1, instance_2])

      translator.to_active_record.should == [instance_2, instance_1]
    end

    it "raises a stale id exception if ActiveRecord doesn't return ids" do
      model_name = double('article', :constantize => model)
      instance = double('instance', :id => 24)
      raw << raw_result(24, model_name)
      raw << raw_result(42, model_name)

      model.should_receive(:where).once.and_return([instance])

      lambda {
        translator.to_active_record
      }.should raise_error(ThinkingSphinx::Search::StaleIdsException) { |err|
        err.ids.should == [42]
      }
    end
  end
end
