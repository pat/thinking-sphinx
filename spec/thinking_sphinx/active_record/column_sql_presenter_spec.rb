require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::ColumnSQLPresenter do
  describe '#with_table' do
    let(:model)        { double 'Model' }
    let(:column)       { double 'Column', :__name => 'column_name',
      :__stack => [], :string? => false }
    let(:adapter)      { double 'Adapter' }
    let(:associations) { double 'Associations' }
    let(:path)         { double 'Path',
      :model => double(:column_names => ['column_name']) }
    let(:presenter) { ThinkingSphinx::ActiveRecord::ColumnSQLPresenter.new(
      model, column, adapter, associations
    ) }

    before do
      stub_const 'Joiner::Path', double(:new => path)
      adapter.stub(:quote) { |arg| "`#{arg}`" }
    end

    context "when there's no explicit db name" do
      before { associations.stub(:alias_for => 'table_name') }

      it 'returns quoted table and column names' do
        presenter.with_table.should == '`table_name`.`column_name`'
      end
    end

    context 'when an eplicit db name is provided' do
      before { associations.stub(:alias_for => 'db_name.table_name') }

      it 'returns properly quoted table name with column name' do
        presenter.with_table.should == '`db_name`.`table_name`.`column_name`'
      end
    end
  end
end
