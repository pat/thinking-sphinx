require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::SQLBuilder do
  let(:source)       { double('source', :model => model, :offset => 3,
    :fields => [], :attributes => [], :disable_range? => false,
    :delta_processor => nil, :conditions => [], :groupings => [],
    :adapter => adapter, :associations => [], :primary_key => :id,
    :options => {}, :properties => []) }
  let(:model)        { double('model', :connection => connection,
    :descends_from_active_record? => true, :column_names => [],
    :inheritance_column => 'type', :unscoped => relation,
    :quoted_table_name => '`users`', :name => 'User') }
  let(:connection)   { double('connection') }
  let(:relation)     { double('relation') }
  let(:config)       { double('config', :indices => indices, :settings => {}) }
  let(:indices)      { double('indices', :count => 5) }
  let(:presenter)    { double('presenter', :to_select => '`name` AS `name`',
    :to_group => '`name`') }
  let(:adapter)      { double('adapter',
    :time_zone_query_pre => ['SET TIME ZONE']) }
  let(:associations) { double('associations', :join_values => []) }
  let(:builder)      { ThinkingSphinx::ActiveRecord::SQLBuilder.new source }

  before :each do
    allow(ThinkingSphinx::Configuration).to receive_messages :instance => config
    allow(ThinkingSphinx::ActiveRecord::PropertySQLPresenter).to receive_messages :new => presenter
    allow(Joiner::Joins).to receive_messages :new => associations
    allow(relation).to receive_messages :select => relation, :where => relation, :group => relation,
      :order => relation, :joins => relation, :to_sql => ''
    allow(connection).to receive(:quote_column_name) { |column| "`#{column}`"}
  end

  describe 'sql_query' do
    before :each do
      allow(source).to receive_messages :type => 'mysql'
    end

    it "adds source associations to the joins of the query" do
      source.associations << double('association',
        :stack => [:user, :posts], :string? => false)

      expect(associations).to receive(:add_join_to).with([:user, :posts])

      builder.sql_query
    end

    it "adds string joins directly to the relation" do
      source.associations << double('association',
        :to_s => 'my string', :string? => true)

      expect(relation).to receive(:joins).with(['my string']).and_return(relation)

      builder.sql_query
    end

    context 'MySQL adapter' do
      before :each do
        allow(source).to receive_messages :type => 'mysql'
      end

      it "returns the relation's query" do
        allow(relation).to receive_messages :to_sql => 'SELECT * FROM people'

        expect(builder.sql_query).to eq('SELECT * FROM people')
      end

      it "ensures results aren't from cache" do
        expect(relation).to receive(:select) do |string|
          expect(string).to match(/^SQL_NO_CACHE /)
          relation
        end

        builder.sql_query
      end

      it "adds the document id using the offset and index count" do
        expect(relation).to receive(:select) do |string|
          expect(string).to match(/`users`.`id` \* 5 \+ 3 AS `id`/)
          relation
        end

        builder.sql_query
      end

      it "adds each field to the SELECT clause" do
        source.fields << double('field')

        expect(relation).to receive(:select) do |string|
          expect(string).to match(/`name` AS `name`/)
          relation
        end

        builder.sql_query
      end

      it "adds each attribute to the SELECT clause" do
        source.attributes << double('attribute')
        allow(presenter).to receive_messages(:to_select => '`created_at` AS `created_at`')

        expect(relation).to receive(:select) do |string|
          expect(string).to match(/`created_at` AS `created_at`/)
          relation
        end

        builder.sql_query
      end

      it "limits results to a set range" do
        expect(relation).to receive(:where) do |string|
          expect(string).to match(/`users`.`id` BETWEEN \$start AND \$end/)
          relation
        end

        builder.sql_query
      end

      it "shouldn't limit results to a range if ranges are disabled" do
        allow(source).to receive_messages :disable_range? => true

        expect(relation).to receive(:where) do |string|
          expect(string).not_to match(/`users`.`id` BETWEEN \$start AND \$end/)
          relation
        end

        builder.sql_query
      end

      it "adds source conditions" do
        source.conditions << 'created_at > NOW()'

        expect(relation).to receive(:where) do |string|
          expect(string).to match(/created_at > NOW()/)
          relation
        end

        builder.sql_query
      end

      it "groups by the primary key" do
        expect(relation).to receive(:group) do |string|
          expect(string).to match(/`users`.`id`/)
          relation
        end

        builder.sql_query
      end

      it "groups each field" do
        source.fields << double('field')

        expect(relation).to receive(:group) do |string|
          expect(string).to match(/`name`/)
          relation
        end

        builder.sql_query
      end

      it "groups each attribute" do
        source.attributes << double('attribute')
        allow(presenter).to receive_messages(:to_group => '`created_at`')

        expect(relation).to receive(:group) do |string|
          expect(string).to match(/`created_at`/)
          relation
        end

        builder.sql_query
      end

      it "groups by source groupings" do
        source.groupings << '`latitude`'

        expect(relation).to receive(:group) do |string|
          expect(string).to match(/`latitude`/)
          relation
        end

        builder.sql_query
      end

      it "orders by NULL" do
        expect(relation).to receive(:order).with('NULL').and_return(relation)

        builder.sql_query
      end

      context 'STI model' do
        before :each do
          model.column_names << 'type'
          allow(model).to receive_messages :descends_from_active_record? => false
          allow(model).to receive_messages :store_full_sti_class => true
        end

        it "groups by the inheritance column" do
          expect(relation).to receive(:group) do |string|
            expect(string).to match(/`users`.`type`/)
            relation
          end

          builder.sql_query
        end

        context 'with a custom inheritance column' do
          before :each do
            model.column_names << 'custom_type'
            allow(model).to receive_messages :inheritance_column => 'custom_type'
          end

          it "groups by the right column" do
            expect(relation).to receive(:group) do |string|
              expect(string).to match(/`users`.`custom_type`/)
              relation
            end

            builder.sql_query
          end
        end
      end

      context 'with a delta processor' do
        let(:processor) { double('processor') }

        before :each do
          allow(source).to receive_messages :delta_processor => processor
          allow(source).to receive_messages :delta? => true
        end

        it "filters by the provided clause" do
          expect(processor).to receive(:clause).with(true).and_return('`delta` = 1')
          expect(relation).to receive(:where) do |string|
            expect(string).to match(/`delta` = 1/)
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
        allow(source).to receive_messages :type => 'pgsql'
        allow(model).to receive_messages :quoted_table_name => '"users"'
        allow(connection).to receive(:quote_column_name) { |column| "\"#{column}\""}
      end

      it "returns the relation's query" do
        allow(relation).to receive_messages :to_sql => 'SELECT * FROM people'

        expect(builder.sql_query).to eq('SELECT * FROM people')
      end

      it "adds the document id using the offset and index count" do
        expect(relation).to receive(:select) do |string|
          expect(string).to match(/"users"."id" \* 5 \+ 3 AS "id"/)
          relation
        end

        builder.sql_query
      end

      it "adds each field to the SELECT clause" do
        source.fields << double('field')

        expect(relation).to receive(:select) do |string|
          expect(string).to match(/"name" AS "name"/)
          relation
        end

        builder.sql_query
      end

      it "adds each attribute to the SELECT clause" do
        source.attributes << double('attribute')
        allow(presenter).to receive_messages(:to_select => '"created_at" AS "created_at"')

        expect(relation).to receive(:select) do |string|
          expect(string).to match(/"created_at" AS "created_at"/)
          relation
        end

        builder.sql_query
      end

      it "limits results to a set range" do
        expect(relation).to receive(:where) do |string|
          expect(string).to match(/"users"."id" BETWEEN \$start AND \$end/)
          relation
        end

        builder.sql_query
      end

      it "shouldn't limit results to a range if ranges are disabled" do
        allow(source).to receive_messages :disable_range? => true

        expect(relation).to receive(:where) do |string|
          expect(string).not_to match(/"users"."id" BETWEEN \$start AND \$end/)
          relation
        end

        builder.sql_query
      end

      it "adds source conditions" do
        source.conditions << 'created_at > NOW()'

        expect(relation).to receive(:where) do |string|
          expect(string).to match(/created_at > NOW()/)
          relation
        end

        builder.sql_query
      end

      it "groups by the primary key" do
        expect(relation).to receive(:group) do |string|
          expect(string).to match(/"users"."id"/)
          relation
        end

        builder.sql_query
      end

      it "groups each field" do
        source.fields << double('field')

        expect(relation).to receive(:group) do |string|
          expect(string).to match(/"name"/)
          relation
        end

        builder.sql_query
      end

      it "groups each attribute" do
        source.attributes << double('attribute')
        allow(presenter).to receive_messages(:to_group => '"created_at"')

        expect(relation).to receive(:group) do |string|
          expect(string).to match(/"created_at"/)
          relation
        end

        builder.sql_query
      end

      it "groups by source groupings" do
        source.groupings << '"latitude"'

        expect(relation).to receive(:group) do |string|
          expect(string).to match(/"latitude"/)
          relation
        end

        builder.sql_query
      end

      it "has no ORDER clause" do
        expect(relation).not_to receive(:order)

        builder.sql_query
      end

      context 'group by shortcut' do
        before :each do
          source.options[:minimal_group_by?] = true
        end

        it "groups by the primary key" do
          expect(relation).to receive(:group) do |string|
            expect(string).to match(/"users"."id"/)
            relation
          end

          builder.sql_query
        end

        it "does not group by fields" do
          source.fields << double('field')

          expect(relation).to receive(:group) do |string|
            expect(string).not_to match(/"name"/)
            relation
          end

          builder.sql_query
        end

        it "does not group by attributes" do
          source.attributes << double('attribute')
          allow(presenter).to receive_messages(:to_group => '"created_at"')

          expect(relation).to receive(:group) do |string|
            expect(string).not_to match(/"created_at"/)
            relation
          end

          builder.sql_query
        end

        it "groups by source groupings" do
          source.groupings << '"latitude"'

          expect(relation).to receive(:group) do |string|
            expect(string).to match(/"latitude"/)
            relation
          end

          builder.sql_query
        end
      end

      context 'group by shortcut in global configuration' do
        before :each do
          config.settings['minimal_group_by'] = true
        end

        it "groups by the primary key" do
          expect(relation).to receive(:group) do |string|
            expect(string).to match(/"users"."id"/)
            relation
          end

          builder.sql_query
        end

        it "does not group by fields" do
          source.fields << double('field')

          expect(relation).to receive(:group) do |string|
            expect(string).not_to match(/"name"/)
            relation
          end

          builder.sql_query
        end

        it "does not group by attributes" do
          source.attributes << double('attribute')
          allow(presenter).to receive_messages(:to_group => '"created_at"')

          expect(relation).to receive(:group) do |string|
            expect(string).not_to match(/"created_at"/)
            relation
          end

          builder.sql_query
        end

        it "groups by source groupings" do
          source.groupings << '"latitude"'

          expect(relation).to receive(:group) do |string|
            expect(string).to match(/"latitude"/)
            relation
          end

          builder.sql_query
        end
      end

      context 'STI model' do
        before :each do
          model.column_names << 'type'
          allow(model).to receive_messages :descends_from_active_record? => false
          allow(model).to receive_messages :store_full_sti_class => true
        end

        it "groups by the inheritance column" do
          expect(relation).to receive(:group) do |string|
            expect(string).to match(/"users"."type"/)
            relation
          end

          builder.sql_query
        end

        context 'with a custom inheritance column' do
          before :each do
            model.column_names << 'custom_type'
            allow(model).to receive_messages :inheritance_column => 'custom_type'
          end

          it "groups by the right column" do
            expect(relation).to receive(:group) do |string|
              expect(string).to match(/"users"."custom_type"/)
              relation
            end

            builder.sql_query
          end
        end
      end

      context 'with a delta processor' do
        let(:processor) { double('processor') }

        before :each do
          allow(source).to receive_messages :delta_processor => processor
          allow(source).to receive_messages :delta? => true
        end

        it "filters by the provided clause" do
          expect(processor).to receive(:clause).with(true).and_return('"delta" = 1')
          expect(relation).to receive(:where) do |string|
            expect(string).to match(/"delta" = 1/)
            relation
          end

          builder.sql_query
        end
      end
    end
  end

  describe 'sql_query_pre' do
    let(:processor) { double('processor', :reset_query => 'RESET DELTAS') }

    before :each do
      allow(source).to receive_messages :options => {}, :delta_processor => nil, :delta? => false
      allow(adapter).to receive_messages :utf8_query_pre => ['SET UTF8']
    end

    it "adds a reset delta query if there is a delta processor and this is the core source" do
      allow(source).to receive_messages :delta_processor => processor

      expect(builder.sql_query_pre).to include('RESET DELTAS')
    end

    it "does not add a reset query if there is no delta processor" do
      expect(builder.sql_query_pre).not_to include('RESET DELTAS')
    end

    it "does not add a reset query if this is a delta source" do
      allow(source).to receive_messages :delta_processor => processor
      allow(source).to receive_messages :delta? => true

      expect(builder.sql_query_pre).not_to include('RESET DELTAS')
    end

    it "sets the group_concat_max_len value if set" do
      source.options[:group_concat_max_len] = 123

      expect(builder.sql_query_pre).
        to include('SET SESSION group_concat_max_len = 123')
    end

    it "does not set the group_concat_max_len if not provided" do
      source.options[:group_concat_max_len] = nil

      expect(builder.sql_query_pre.select { |sql|
        sql[/SET SESSION group_concat_max_len/]
      }).to be_empty
    end

    it "sets the connection to use UTF-8 if required" do
      source.options[:utf8?] = true

      expect(builder.sql_query_pre).to include('SET UTF8')
    end

    it "does not set the connection to use UTF-8 if not required" do
      source.options[:utf8?] = false

      expect(builder.sql_query_pre).not_to include('SET UTF8')
    end

    it "adds a time-zone query by default" do
      expect(builder.sql_query_pre).to include('SET TIME ZONE')
    end

    it "does not add a time-zone query if requested" do
      config.settings['skip_time_zone'] = true

      expect(builder.sql_query_pre).to_not include('SET TIME ZONE')
    end
  end

  describe 'sql_query_range' do
    before :each do
      allow(adapter).to receive(:convert_nulls) { |string, default|
        "ISNULL(#{string}, #{default})"
      }
    end

    it "returns the relation's query" do
      allow(relation).to receive_messages :to_sql => 'SELECT * FROM people'

      expect(builder.sql_query_range).to eq('SELECT * FROM people')
    end

    it "returns nil if ranges are disabled" do
      allow(source).to receive_messages :disable_range? => true

      expect(builder.sql_query_range).to be_nil
    end

    it "selects the minimum primary key value, allowing for nulls" do
      expect(relation).to receive(:select) do |string|
        expect(string).to match(/ISNULL\(MIN\(`users`.`id`\), 1\)/)
        relation
      end

      builder.sql_query_range
    end

    it "selects the maximum primary key value, allowing for nulls" do
      expect(relation).to receive(:select) do |string|
        expect(string).to match(/ISNULL\(MAX\(`users`.`id`\), 1\)/)
        relation
      end

      builder.sql_query_range
    end

    it "shouldn't limit results to a range" do
      expect(relation).to receive(:where) do |string|
        expect(string).not_to match(/`users`.`id` BETWEEN \$start AND \$end/)
        relation
      end

      builder.sql_query_range
    end

    it "does not add source conditions" do
      source.conditions << 'created_at > NOW()'

      expect(relation).to receive(:where) do |string|
        expect(string).not_to match(/created_at > NOW()/)
        relation
      end

      builder.sql_query_range
    end

    context 'with a delta processor' do
      let(:processor) { double('processor') }

      before :each do
        allow(source).to receive_messages :delta_processor => processor
        allow(source).to receive_messages :delta? => true
      end

      it "filters by the provided clause" do
        expect(processor).to receive(:clause).with(true).and_return('`delta` = 1')
        expect(relation).to receive(:where) do |string|
          expect(string).to match(/`delta` = 1/)
          relation
        end

        builder.sql_query_range
      end
    end
  end
end
