require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::PropertySQLPresenter do
  let(:adapter)      { double 'adapter' }
  let(:associations) { double 'associations', :alias_for => 'articles' }
  let(:model)        { double :column_names => ['title', 'created_at'] }
  let(:path)         { double :aggregate? => false, :model => model }

  before :each do
    allow(adapter).to receive(:quote) { |column| column }

    stub_const 'Joiner::Path', double(:new => path)
  end

  context 'with a field' do
    let(:presenter) {
      ThinkingSphinx::ActiveRecord::PropertySQLPresenter.new(
        field, adapter, associations
      )
    }
    let(:field)     { double('field', :name => 'title', :columns => [column],
      :type => nil, :multi? => false, :source_type => nil, :model => double) }
    let(:column)    { double('column', :string? => false, :__stack => [],
      :__name => 'title') }

    describe '#to_group' do
      it "returns the column name as a string" do
        expect(presenter.to_group).to eq('articles.title')
      end

      it "gets the column's table alias from the associations object" do
        allow(column).to receive_messages(:__stack => [:users, :posts])

        expect(associations).to receive(:alias_for).with([:users, :posts]).
          and_return('posts')

        presenter.to_group
      end

      it "returns nil if the property is an aggregate" do
        allow(path).to receive_messages :aggregate? => true

        expect(presenter.to_group).to be_nil
      end

      it "returns nil if the field is sourced via a separate query" do
        allow(field).to receive_messages :source_type => 'query'

        expect(presenter.to_group).to be_nil
      end
    end

    describe '#to_select' do
      it "returns the column name as a string" do
        expect(presenter.to_select).to eq('articles.title AS title')
      end

      it "gets the column's table alias from the associations object" do
        allow(column).to receive_messages(:__stack => [:users, :posts])

        expect(associations).to receive(:alias_for).with([:users, :posts]).
          and_return('posts')

        presenter.to_select
      end

      it "returns the column name with an alias when provided" do
        allow(field).to receive_messages(:name => :subject)

        expect(presenter.to_select).to eq('articles.title AS subject')
      end

      it "groups and concatenates aggregated columns" do
        allow(adapter).to receive :group_concatenate do |clause, separator|
          "GROUP_CONCAT(#{clause} SEPARATOR '#{separator}')"
        end

        allow(path).to receive_messages :aggregate? => true

        expect(presenter.to_select).
          to eq("GROUP_CONCAT(articles.title SEPARATOR ' ') AS title")
      end

      it "concatenates multiple columns" do
        allow(adapter).to receive :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end

        allow(field).to receive_messages(:columns => [column, column])

        expect(presenter.to_select).
          to eq("CONCAT_WS(' ', articles.title, articles.title) AS title")
      end

      it "does not include columns that don't exist" do
        allow(adapter).to receive :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end

        allow(field).to receive_messages(:columns => [column, double('column', :string? => false,
          :__stack => [], :__name => 'body')])

        expect(presenter.to_select).
          to eq("CONCAT_WS(' ', articles.title) AS title")
      end

      it "returns nil for query sourced fields" do
        allow(field).to receive_messages :source_type => :query

        expect(presenter.to_select).to be_nil
      end

      it "returns nil for ranged query sourced fields" do
        allow(field).to receive_messages :source_type => :ranged_query

        expect(presenter.to_select).to be_nil
      end
    end
  end

  context 'with an attribute' do
    let(:presenter) {
      ThinkingSphinx::ActiveRecord::PropertySQLPresenter.new(
        attribute, adapter, associations
      )
    }
    let(:attribute) { double('attribute', :name => 'created_at',
      :columns => [column], :type => :integer, :multi? => false,
      :source_type => nil, :model => double) }
    let(:column)    { double('column', :string? => false, :__stack => [],
      :__name => 'created_at') }

    before :each do
      allow(adapter).to receive :cast_to_timestamp do |clause|
        "UNIX_TIMESTAMP(#{clause})"
      end
    end

    describe '#to_group' do
      it "returns the column name as a string" do
        expect(presenter.to_group).to eq('articles.created_at')
      end

      it "gets the column's table alias from the associations object" do
        allow(column).to receive_messages(:__stack => [:users, :posts])

        expect(associations).to receive(:alias_for).with([:users, :posts]).
          and_return('posts')

        presenter.to_group
      end

      it "returns nil if the column is a string" do
        allow(column).to receive_messages(:string? => true)

        expect(presenter.to_group).to be_nil
      end

      it "returns nil if the property is an aggregate" do
        allow(path).to receive_messages :aggregate? => true

        expect(presenter.to_group).to be_nil
      end

      it "returns nil if the attribute is sourced via a separate query" do
        allow(attribute).to receive_messages :source_type => 'query'

        expect(presenter.to_group).to be_nil
      end
    end

    describe '#to_select' do
      it "returns the column name as a string" do
        expect(presenter.to_select).to eq('articles.created_at AS created_at')
      end

      it "gets the column's table alias from the associations object" do
        allow(column).to receive_messages(:__stack => [:users, :posts])

        expect(associations).to receive(:alias_for).with([:users, :posts]).
          and_return('posts')

        presenter.to_select
      end

      it "returns the column name with an alias when provided" do
        allow(attribute).to receive_messages(:name => :creation_timestamp)

        expect(presenter.to_select).
          to eq('articles.created_at AS creation_timestamp')
      end

      it "ensures datetime attributes are converted to timestamps" do
        allow(attribute).to receive_messages :type => :timestamp

        expect(presenter.to_select).
          to eq('UNIX_TIMESTAMP(articles.created_at) AS created_at')
      end

      it "does not include columns that don't exist" do
        allow(adapter).to receive :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end
        allow(adapter).to receive :cast_to_string do |clause|
          "CAST(#{clause} AS varchar)"
        end

        allow(attribute).to receive_messages(:columns => [column, double('column',
          :string? => false, :__stack => [], :__name => 'updated_at')])

        expect(presenter.to_select).to eq("CONCAT_WS(',', CAST(articles.created_at AS varchar)) AS created_at")
      end

      it "casts and concatenates multiple columns for attributes" do
        allow(adapter).to receive :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end
        allow(adapter).to receive :cast_to_string do |clause|
          "CAST(#{clause} AS varchar)"
        end

        allow(attribute).to receive_messages(:columns => [column, column])

        expect(presenter.to_select).to eq("CONCAT_WS(',', CAST(articles.created_at AS varchar), CAST(articles.created_at AS varchar)) AS created_at")
      end

      it "double-casts and concatenates multiple columns for timestamp attributes" do
        allow(adapter).to receive :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end
        allow(adapter).to receive :cast_to_string do |clause|
          "CAST(#{clause} AS varchar)"
        end

        allow(attribute).to receive_messages :columns => [column, column], :type => :timestamp

        expect(presenter.to_select).to eq("CONCAT_WS(',', CAST(UNIX_TIMESTAMP(articles.created_at) AS varchar), CAST(UNIX_TIMESTAMP(articles.created_at) AS varchar)) AS created_at")
      end

      it "does not split attribute clause for timestamp casting if it looks like a function call" do
        allow(column).to receive_messages :__name => "COALESCE(articles.updated_at, articles.created_at)", :string? => true

        allow(attribute).to receive_messages :name => 'mod_date', :columns => [column],
          :type => :timestamp

        expect(presenter.to_select).to eq("UNIX_TIMESTAMP(COALESCE(articles.updated_at, articles.created_at)) AS mod_date")
      end

      it "returns nil for query sourced attributes" do
        allow(attribute).to receive_messages :source_type => :query

        expect(presenter.to_select).to be_nil
      end

      it "returns nil for ranged query sourced attributes" do
        allow(attribute).to receive_messages :source_type => :ranged_query

        expect(presenter.to_select).to be_nil
      end
    end
  end
end
