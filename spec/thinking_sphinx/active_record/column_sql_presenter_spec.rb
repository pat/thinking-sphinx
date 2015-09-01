require 'spec_helper'

module ThinkingSphinx
  module ActiveRecord
    describe ColumnSQLPresenter do
      describe '#with_table' do
        let(:model) { double }
        let(:column) { double(__name: 'column_name', string?: false) }
        let(:adapter) { double }
        let(:associations) { double }

        let(:c_p) do
          ColumnSQLPresenter.new(model, column, adapter, associations)
        end

        before do
          adapter.stub(:quote) do |arg|
            "`#{arg}`"
          end

          c_p.stub(exists?: true)
        end

        context "when there's no explicit db name" do
          before { c_p.stub(table: 'table_name') }

          it 'returns quoted table and column names' do
            c_p.with_table.should == '`table_name`.`column_name`'
          end
        end

        context 'when an eplicit db name is provided' do
          before { c_p.stub(table: 'db_name.table_name') }

          it 'returns properly quoted table name with column name' do
            c_p.with_table.should == '`db_name`.`table_name`.`column_name`'
          end
        end
      end
    end
  end
end
