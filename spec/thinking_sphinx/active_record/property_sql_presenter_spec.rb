require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::PropertySQLPresenter do
  let(:adapter)      { double 'adapter' }
  let(:associations) { double 'associations', :alias_for => 'articles',
    :aggregate_for? => false, :model_for => model }
  let(:model)        { double :column_names => ['title', 'created_at'] }

  before :each do
    adapter.stub(:quote) { |column| column }
  end

  context 'with a field' do
    let(:presenter) {
      ThinkingSphinx::ActiveRecord::PropertySQLPresenter.new(
        field, adapter, associations
      )
    }
    let(:field)     { double('field', :name => 'title', :columns => [column],
      :type => nil, :multi? => false, :source_type => nil) }
    let(:column)    { double('column', :string? => false, :__stack => [],
      :__name => 'title') }

    describe '#to_group' do
      it "returns the column name as a string" do
        presenter.to_group.should == 'articles.title'
      end

      it "gets the column's table alias from the associations object" do
        column.stub!(:__stack => [:users, :posts])

        associations.should_receive(:alias_for).with([:users, :posts]).
          and_return('posts')

        presenter.to_group
      end

      it "returns nil if the property is an aggregate" do
        associations.stub! :aggregate_for? => true

        presenter.to_group.should be_nil
      end

      it "returns nil if the field is sourced via a separate query" do
        field.stub :source_type => 'query'

        presenter.to_group.should be_nil
      end
    end

    describe '#to_select' do
      it "returns the column name as a string" do
        presenter.to_select.should == 'articles.title AS title'
      end

      it "gets the column's table alias from the associations object" do
        column.stub!(:__stack => [:users, :posts])

        associations.should_receive(:alias_for).with([:users, :posts]).
          and_return('posts')

        presenter.to_select
      end

      it "returns the column name with an alias when provided" do
        field.stub!(:name => :subject)

        presenter.to_select.should == 'articles.title AS subject'
      end

      it "groups and concatenates aggregated columns" do
        adapter.stub :group_concatenate do |clause, separator|
          "GROUP_CONCAT(#{clause} SEPARATOR '#{separator}')"
        end

        associations.stub! :aggregate_for? => true

        presenter.to_select.
          should == "GROUP_CONCAT(articles.title SEPARATOR ' ') AS title"
      end

      it "concatenates multiple columns" do
        adapter.stub :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end

        field.stub!(:columns => [column, column])

        presenter.to_select.
          should == "CONCAT_WS(' ', articles.title, articles.title) AS title"
      end

      it "does not include columns that don't exist" do
        adapter.stub :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end

        field.stub!(:columns => [column, double('column', :string? => false,
          :__stack => [], :__name => 'body')])

        presenter.to_select.
          should == "CONCAT_WS(' ', articles.title) AS title"
      end

      it "returns nil for query sourced fields" do
        field.stub :source_type => :query

        presenter.to_select.should be_nil
      end

      it "returns nil for ranged query sourced fields" do
        field.stub :source_type => :ranged_query

        presenter.to_select.should be_nil
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
      :source_type => nil) }
    let(:column)    { double('column', :string? => false, :__stack => [],
      :__name => 'created_at') }

    before :each do
      adapter.stub :cast_to_timestamp do |clause|
        "UNIX_TIMESTAMP(#{clause})"
      end
    end

    describe '#to_group' do
      it "returns the column name as a string" do
        presenter.to_group.should == 'articles.created_at'
      end

      it "gets the column's table alias from the associations object" do
        column.stub!(:__stack => [:users, :posts])

        associations.should_receive(:alias_for).with([:users, :posts]).
          and_return('posts')

        presenter.to_group
      end

      it "returns nil if the column is a string" do
        column.stub!(:string? => true)

        presenter.to_group.should be_nil
      end

      it "returns nil if the property is an aggregate" do
        associations.stub! :aggregate_for? => true

        presenter.to_group.should be_nil
      end

      it "returns nil if the attribute is sourced via a separate query" do
        attribute.stub :source_type => 'query'

        presenter.to_group.should be_nil
      end
    end

    describe '#to_select' do
      it "returns the column name as a string" do
        presenter.to_select.should == 'articles.created_at AS created_at'
      end

      it "gets the column's table alias from the associations object" do
        column.stub!(:__stack => [:users, :posts])

        associations.should_receive(:alias_for).with([:users, :posts]).
          and_return('posts')

        presenter.to_select
      end

      it "returns the column name with an alias when provided" do
        attribute.stub!(:name => :creation_timestamp)

        presenter.to_select.
          should == 'articles.created_at AS creation_timestamp'
      end

      it "ensures datetime attributes are converted to timestamps" do
        attribute.stub :type => :timestamp

        presenter.to_select.
          should == 'UNIX_TIMESTAMP(articles.created_at) AS created_at'
      end

      it "does not include columns that don't exist" do
        adapter.stub :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end
        adapter.stub :cast_to_string do |clause|
          "CAST(#{clause} AS varchar)"
        end

        attribute.stub!(:columns => [column, double('column',
          :string? => false, :__stack => [], :__name => 'updated_at')])

        presenter.to_select.should == "CONCAT_WS(',', CAST(articles.created_at AS varchar)) AS created_at"
      end

      it "casts and concatenates multiple columns for attributes" do
        adapter.stub :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end
        adapter.stub :cast_to_string do |clause|
          "CAST(#{clause} AS varchar)"
        end

        attribute.stub!(:columns => [column, column])

        presenter.to_select.should == "CONCAT_WS(',', CAST(articles.created_at AS varchar), CAST(articles.created_at AS varchar)) AS created_at"
      end

      it "double-casts and concatenates multiple columns for timestamp attributes" do
        adapter.stub :concatenate do |clause, separator|
          "CONCAT_WS('#{separator}', #{clause})"
        end
        adapter.stub :cast_to_string do |clause|
          "CAST(#{clause} AS varchar)"
        end

        attribute.stub :columns => [column, column], :type => :timestamp

        presenter.to_select.should == "CONCAT_WS(',', CAST(UNIX_TIMESTAMP(articles.created_at) AS varchar), CAST(UNIX_TIMESTAMP(articles.created_at) AS varchar)) AS created_at"
      end

      it "does not split attribute clause for timestamp casting if it looks like a function call" do
        column.stub :__name => "COALESCE(articles.updated_at, articles.created_at)"
        column.stub :string? => true

        attribute.stub :name    => 'mod_date'
        attribute.stub :columns => [column]
        attribute.stub :type    => :timestamp

        presenter.to_select.should == "UNIX_TIMESTAMP(COALESCE(articles.updated_at, articles.created_at)) AS mod_date"
      end

      it "returns nil for query sourced attributes" do
        attribute.stub :source_type => :query

        presenter.to_select.should be_nil
      end

      it "returns nil for ranged query sourced attributes" do
        attribute.stub :source_type => :ranged_query

        presenter.to_select.should be_nil
      end
    end
  end
end
