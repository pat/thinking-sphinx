require 'spec_helper'

describe ThinkingSphinx::Deltas::DefaultDelta do
  let(:delta)   { ThinkingSphinx::Deltas::DefaultDelta.new adapter }
  let(:adapter) {
    double('adapter', :quoted_table_name => 'articles', :quote => 'delta')
  }

  describe '#clause' do
    context 'for a delta source' do
      before :each do
        adapter.stub :boolean_value => 't'
      end

      it "limits results to those flagged as deltas" do
        delta.clause(true).should == "articles.delta = t"
      end
    end
  end

  describe '#reset_query' do
    it "updates the table to set delta flags to false" do
      adapter.stub(:boolean_value) { |value| value ? 't' : 'f' }
      delta.reset_query.
        should == 'UPDATE articles SET delta = f WHERE delta = t'
    end
  end
end
