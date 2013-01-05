require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::SQLBuilder do
  let(:source)       { double('source', :model => model, :offset => 3,
    :fields => [], :attributes => [], :disable_range? => false,
    :delta_processor => nil, :conditions => [], :groupings => [],
    :adapter => adapter, :associations => [], :primary_key => :id) }
  let(:model)        { double('model', :connection => connection,
    :descends_from_active_record? => true, :column_names => [],
    :inheritance_column => 'type', :unscoped => relation,
    :quoted_table_name => '`users`', :name => 'User') }
  let(:connection)   { double('connection') }
  let(:relation)     { double('relation') }
  let(:config)       { double('config', :indices => indices) }
  let(:indices)      { double('indices', :count => 5) }
  let(:presenter)    { double('presenter', :to_select => '`name` AS `name`',
    :to_group => '`name`') }
  let(:adapter)      { double('adapter') }
  let(:associations) { double('associations', :join_values => []) }
  let(:builder)      { ThinkingSphinx::ActiveRecord::SQLBuilder.new source }

  before :each do
    ThinkingSphinx::Configuration.stub! :instance => config
    ThinkingSphinx::ActiveRecord::PropertySQLPresenter.stub! :new => presenter
    ThinkingSphinx::ActiveRecord::Associations.stub! :new => associations
    relation.stub! :select => relation, :where => relation, :group => relation,
      :order => relation, :joins => relation, :to_sql => ''
    connection.stub!(:quote_column_name) { |column| "`#{column}`"}
  end

  describe 'sql_query' do
    before :each do
      source.stub! :type => 'mysql'
    end

    it "adds source associations to the joins of the query" do
      source.associations << double('association',
        :stack => [:user, :posts], :string? => false)

      associations.should_receive(:add_join_to).with([:user, :posts])

      builder.sql_query
    end

    it "adds string joins directly to the relation" do
      source.associations << double('association',
        :to_s => 'my string', :string? => true)

      relation.should_receive(:joins).with(['my string']).and_return(relation)

      builder.sql_query
    end

    context 'MySQL adapter' do
      before :each do
        source.stub! :type => 'mysql'
      end

      it "returns the relation's query" do
        relation.stub! :to_sql => 'SELECT * FROM people'

        builder.sql_query.should == 'SELECT * FROM people'
      end

      it "ensures results aren't from cache" do
        relation.should_receive(:select) do |string|
          string.should match(/^SQL_NO_CACHE /)
          relation
        end

        builder.sql_query
      end

      it "adds the document id using the offset and index count" do
        relation.should_receive(:select) do |string|
          string.should match(/`users`.`id` \* 5 \+ 3 AS `id`/)
          relation
        end

        builder.sql_query
      end

      it "adds each field to the SELECT clause" do
        source.fields << double('field')

        relation.should_receive(:select) do |string|
          string.should match(/`name` AS `name`/)
          relation
        end

        builder.sql_query
      end

      it "adds each attribute to the SELECT clause" do
        source.attributes << double('attribute')
        presenter.stub!(:to_select => '`created_at` AS `created_at`')

        relation.should_receive(:select) do |string|
          string.should match(/`created_at` AS `created_at`/)
          relation
        end

        builder.sql_query
      end

      it "limits results to a set range" do
        relation.should_receive(:where) do |string|
          string.should match(/`users`.`id` >= \$start/)
          string.should match(/`users`.`id` <= \$end/)
          relation
        end

        builder.sql_query
      end

      it "shouldn't limit results to a range if ranges are disabled" do
        source.stub! :disable_range? => true

        relation.should_receive(:where) do |string|
          string.should_not match(/`users`.`id` >= \$start/)
          string.should_not match(/`users`.`id` <= \$end/)
          relation
        end

        builder.sql_query
      end

      it "adds source conditions" do
        source.conditions << 'created_at > NOW()'

        relation.should_receive(:where) do |string|
          string.should match(/created_at > NOW()/)
          relation
        end

        builder.sql_query
      end

      it "groups by the primary key" do
        relation.should_receive(:group) do |string|
          string.should match(/`users`.`id`/)
          relation
        end

        builder.sql_query
      end

      it "groups each field" do
        source.fields << double('field')

        relation.should_receive(:group) do |string|
          string.should match(/`name`/)
          relation
        end

        builder.sql_query
      end

      it "groups each attribute" do
        source.attributes << double('attribute')
        presenter.stub!(:to_group => '`created_at`')

        relation.should_receive(:group) do |string|
          string.should match(/`created_at`/)
          relation
        end

        builder.sql_query
      end

      it "groups by source groupings" do
        source.groupings << '`latitude`'

        relation.should_receive(:group) do |string|
          string.should match(/`latitude`/)
          relation
        end

        builder.sql_query
      end

      it "orders by NULL" do
        relation.should_receive(:order).with('NULL').and_return(relation)

        builder.sql_query
      end

      context 'STI model' do
        before :each do
          model.column_names << 'type'
          model.stub! :descends_from_active_record? => false
          model.stub! :store_full_sti_class => true
        end

        it "limits results to just the model" do
          relation.should_receive(:where) do |string|
            string.should match(/`users`.`type` = 'User'/)
            relation
          end

          builder.sql_query
        end

        it "uses the demodulised name if that's what is stored" do
          model.stub! :store_full_sti_class => false
          model.name.stub! :demodulize => 'U'

          relation.should_receive(:where) do |string|
            string.should match(/`users`.`type` = 'U'/)
            relation
          end

          builder.sql_query
        end

        it "groups by the inheritance column" do
          relation.should_receive(:group) do |string|
            string.should match(/`users`.`type`/)
            relation
          end

          builder.sql_query
        end

        context 'with a custom inheritance column' do
          before :each do
            model.column_names << 'custom_type'
            model.stub :inheritance_column => 'custom_type'
          end

          it "limits results on the right column" do
            relation.should_receive(:where) do |string|
              string.should match(/`users`.`custom_type` = 'User'/)
              relation
            end

            builder.sql_query
          end

          it "groups by the right column" do
            relation.should_receive(:group) do |string|
              string.should match(/`users`.`custom_type`/)
              relation
            end

            builder.sql_query
          end
        end
      end

      context 'with a delta processor' do
        let(:processor) { double('processor') }

        before :each do
          source.stub! :delta_processor => processor
          source.stub! :delta? => true
        end

        it "filters by the provided clause" do
          processor.should_receive(:clause).with(true).and_return('`delta` = 1')
          relation.should_receive(:where) do |string|
            string.should match(/`delta` = 1/)
            relation
          end

          builder.sql_query
        end
      end
    end

    context 'PostgreSQL adapter' do
      let(:presenter) { double('presenter', :to_select => '"name" AS "name"',
        :to_group => '"name"') }

      before :each do
        source.stub! :type => 'pgsql'
        model.stub! :quoted_table_name => '"users"'
        connection.stub!(:quote_column_name) { |column| "\"#{column}\""}
      end

      it "returns the relation's query" do
        relation.stub! :to_sql => 'SELECT * FROM people'

        builder.sql_query.should == 'SELECT * FROM people'
      end

      it "adds the document id using the offset and index count" do
        relation.should_receive(:select) do |string|
          string.should match(/"users"."id" \* 5 \+ 3 AS "id"/)
          relation
        end

        builder.sql_query
      end

      it "adds each field to the SELECT clause" do
        source.fields << double('field')

        relation.should_receive(:select) do |string|
          string.should match(/"name" AS "name"/)
          relation
        end

        builder.sql_query
      end

      it "adds each attribute to the SELECT clause" do
        source.attributes << double('attribute')
        presenter.stub!(:to_select => '"created_at" AS "created_at"')

        relation.should_receive(:select) do |string|
          string.should match(/"created_at" AS "created_at"/)
          relation
        end

        builder.sql_query
      end

      it "limits results to a set range" do
        relation.should_receive(:where) do |string|
          string.should match(/"users"."id" >= \$start/)
          string.should match(/"users"."id" <= \$end/)
          relation
        end

        builder.sql_query
      end

      it "shouldn't limit results to a range if ranges are disabled" do
        source.stub! :disable_range? => true

        relation.should_receive(:where) do |string|
          string.should_not match(/"users"."id" >= \$start/)
          string.should_not match(/"users"."id" <= \$end/)
          relation
        end

        builder.sql_query
      end

      it "adds source conditions" do
        source.conditions << 'created_at > NOW()'

        relation.should_receive(:where) do |string|
          string.should match(/created_at > NOW()/)
          relation
        end

        builder.sql_query
      end

      it "groups by the primary key" do
        relation.should_receive(:group) do |string|
          string.should match(/"users"."id"/)
          relation
        end

        builder.sql_query
      end

      it "groups each field" do
        source.fields << double('field')

        relation.should_receive(:group) do |string|
          string.should match(/"name"/)
          relation
        end

        builder.sql_query
      end

      it "groups each attribute" do
        source.attributes << double('attribute')
        presenter.stub!(:to_group => '"created_at"')

        relation.should_receive(:group) do |string|
          string.should match(/"created_at"/)
          relation
        end

        builder.sql_query
      end

      it "groups by source groupings" do
        source.groupings << '"latitude"'

        relation.should_receive(:group) do |string|
          string.should match(/"latitude"/)
          relation
        end

        builder.sql_query
      end

      it "has no ORDER clause" do
        relation.should_not_receive(:order)

        builder.sql_query
      end

      context 'STI model' do
        before :each do
          model.column_names << 'type'
          model.stub! :descends_from_active_record? => false
          model.stub! :store_full_sti_class => true
        end

        it "limits results to just the model" do
          relation.should_receive(:where) do |string|
            string.should match(/"users"."type" = 'User'/)
            relation
          end

          builder.sql_query
        end

        it "uses the demodulised name if that's what is stored" do
          model.stub! :store_full_sti_class => false
          model.name.stub! :demodulize => 'U'

          relation.should_receive(:where) do |string|
            string.should match(/"users"."type" = 'U'/)
            relation
          end

          builder.sql_query
        end

        it "groups by the inheritance column" do
          relation.should_receive(:group) do |string|
            string.should match(/"users"."type"/)
            relation
          end

          builder.sql_query
        end

        context 'with a custom inheritance column' do
          before :each do
            model.column_names << 'custom_type'
            model.stub :inheritance_column => 'custom_type'
          end

          it "limits results on the right column" do
            relation.should_receive(:where) do |string|
              string.should match(/"users"."custom_type" = 'User'/)
              relation
            end

            builder.sql_query
          end

          it "groups by the right column" do
            relation.should_receive(:group) do |string|
              string.should match(/"users"."custom_type"/)
              relation
            end

            builder.sql_query
          end
        end
      end

      context 'with a delta processor' do
        let(:processor) { double('processor') }

        before :each do
          source.stub! :delta_processor => processor
          source.stub! :delta? => true
        end

        it "filters by the provided clause" do
          processor.should_receive(:clause).with(true).and_return('"delta" = 1')
          relation.should_receive(:where) do |string|
            string.should match(/"delta" = 1/)
            relation
          end

          builder.sql_query
        end
      end
    end
  end

  describe 'sql_query_info' do
    it "filters on the reversed document id" do
      relation.should_receive(:where).
        with("`users`.`id` = ($id - #{source.offset}) / #{indices.count}").
        and_return(relation)

      builder.sql_query_info
    end

    it "returns the generated SQL query" do
      relation.stub(:to_sql).and_return('SELECT * FROM people WHERE id = $id')

      builder.sql_query_info.should == 'SELECT * FROM people WHERE id = $id'
    end
  end

  describe 'sql_query_pre' do
    let(:processor) { double('processor', :reset_query => 'RESET DELTAS') }

    before :each do
      source.stub :options => {}, :delta_processor => nil, :delta? => false
      adapter.stub :utf8_query_pre => 'SET UTF8'
    end

    it "adds a reset delta query if there is a delta processor and this is the core source" do
      source.stub :delta_processor => processor

      builder.sql_query_pre.should include('RESET DELTAS')
    end

    it "does not add a reset query if there is no delta processor" do
      builder.sql_query_pre.should_not include('RESET DELTAS')
    end

    it "does not add a reset query if this is a delta source" do
      source.stub :delta_processor => processor
      source.stub :delta? => true

      builder.sql_query_pre.should_not include('RESET DELTAS')
    end

    it "sets the group_concat_max_len value if set" do
      source.options[:group_concat_max_len] = 123

      builder.sql_query_pre.
        should include('SET SESSION group_concat_max_len = 123')
    end

    it "does not set the group_concat_max_len if not provided" do
      source.options[:group_concat_max_len] = nil

      builder.sql_query_pre.select { |sql|
        sql[/SET SESSION group_concat_max_len/]
      }.should be_empty
    end

    it "sets the connection to use UTF-8 if required" do
      source.options[:utf8?] = true

      builder.sql_query_pre.should include('SET UTF8')
    end

    it "does not set the connection to use UTF-8 if not required" do
      source.options[:utf8?] = false

      builder.sql_query_pre.should_not include('SET UTF8')
    end
  end

  describe 'sql_query_range' do
    before :each do
      adapter.stub!(:convert_nulls) { |string, default|
        "ISNULL(#{string}, #{default})"
      }
    end

    it "returns the relation's query" do
      relation.stub! :to_sql => 'SELECT * FROM people'

      builder.sql_query_range.should == 'SELECT * FROM people'
    end

    it "returns nil if ranges are disabled" do
      source.stub! :disable_range? => true

      builder.sql_query_range.should be_nil
    end

    it "selects the minimum primary key value, allowing for nulls" do
      relation.should_receive(:select) do |string|
        string.should match(/ISNULL\(MIN\(`users`.`id`\), 1\)/)
        relation
      end

      builder.sql_query_range
    end

    it "selects the maximum primary key value, allowing for nulls" do
      relation.should_receive(:select) do |string|
        string.should match(/ISNULL\(MAX\(`users`.`id`\), 1\)/)
        relation
      end

      builder.sql_query_range
    end

    it "shouldn't limit results to a range" do
      relation.should_receive(:where) do |string|
        string.should_not match(/`users`.`id` >= \$start/)
        string.should_not match(/`users`.`id` <= \$end/)
        relation
      end

      builder.sql_query_range
    end

    it "adds source conditions" do
      source.conditions << 'created_at > NOW()'

      relation.should_receive(:where) do |string|
        string.should match(/created_at > NOW()/)
        relation
      end

      builder.sql_query_range
    end

    context 'STI model' do
      before :each do
        model.column_names << 'type'
        model.stub! :descends_from_active_record? => false
        model.stub! :store_full_sti_class => true
      end

      it "limits results to just the model" do
        relation.should_receive(:where) do |string|
          string.should match(/`users`.`type` = 'User'/)
          relation
        end

        builder.sql_query_range
      end

      it "uses the demodulised name if that's what is stored" do
        model.stub! :store_full_sti_class => false
        model.name.stub! :demodulize => 'U'

        relation.should_receive(:where) do |string|
          string.should match(/`users`.`type` = 'U'/)
          relation
        end

        builder.sql_query_range
      end

      context 'with a custom inheritance column' do
        before :each do
          model.column_names << 'custom_type'
          model.stub :inheritance_column => 'custom_type'
        end

        it "limits results on the right column" do
          relation.should_receive(:where) do |string|
            string.should match(/`users`.`custom_type` = 'User'/)
            relation
          end

          builder.sql_query_range
        end
      end
    end

    context 'with a delta processor' do
      let(:processor) { double('processor') }

      before :each do
        source.stub! :delta_processor => processor
        source.stub! :delta? => true
      end

      it "filters by the provided clause" do
        processor.should_receive(:clause).with(true).and_return('`delta` = 1')
        relation.should_receive(:where) do |string|
          string.should match(/`delta` = 1/)
          relation
        end

        builder.sql_query_range
      end
    end
  end
end
