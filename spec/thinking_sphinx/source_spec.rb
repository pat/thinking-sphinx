require 'spec_helper'

describe ThinkingSphinx::Source do
  before :each do
    @index  = ThinkingSphinx::Index.new(Person)
    @source = ThinkingSphinx::Source.new(@index, :sql_range_step => 1000)
  end

  describe '#initialize' do
    it "should store the current connection details" do
      config = Person.connection.instance_variable_get(:@config)
      @source.database_configuration.should == config
    end
  end

  it "should generate the name from the model" do
    @source.name.should == "person"
  end

  it "should handle namespaced models for name generation" do
    index  = ThinkingSphinx::Index.new(Admin::Person)
    source = ThinkingSphinx::Source.new(index)
    source.name.should == "admin_person"
  end

  describe "#to_riddle_for_core" do
    before :each do
      config = ThinkingSphinx::Configuration.instance
      config.source_options[:sql_ranged_throttle] = 100

      ThinkingSphinx::Field.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:first_name)
      )
      ThinkingSphinx::Field.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:last_name)
      )

      ThinkingSphinx::Attribute.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:id), :as => :internal_id
      )
      ThinkingSphinx::Attribute.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:birthday)
      )
      ThinkingSphinx::Attribute.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:tags, :id), :as => :tag_ids
      )
      ThinkingSphinx::Attribute.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:contacts, :id),
        :as => :contact_ids, :source => :query
      )
      ThinkingSphinx::Attribute.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:source, :id),
        :as => :source_id, :type => :integer
      )

      ThinkingSphinx::Join.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:links)
      )

      @source.conditions << "`birthday` <= NOW()"
      @source.groupings  << "`first_name`"

      @index.local_options[:group_concat_max_len] = 1024

      @riddle = @source.to_riddle_for_core(1, 0)
    end

    it "should generate a Riddle Source object" do
      @riddle.should be_a_kind_of(Riddle::Configuration::SQLSource)
    end

    it "should use the index and name its own name" do
      @riddle.name.should == "person_core_0"
    end

    it "should use the model's database connection to determine type" do
      @riddle.type.should == "mysql"
    end

    it "should match the model's database settings" do
      config = Person.connection.instance_variable_get(:@config)
      @riddle.sql_db.should   == config[:database]
      @riddle.sql_user.should == config[:username]
      @riddle.sql_pass.should == config[:password].to_s
      @riddle.sql_host.should == config[:host]
      @riddle.sql_port.should == config[:port]
      @riddle.sql_sock.should == config[:socket]
    end

    it "should use a environment user if nothing else is provided" do
      Person.connection.stub!(:instance_variable_get => {
        :user     => nil,
        :username => nil
      })
      @source = ThinkingSphinx::Source.new(@index)

      riddle = @source.to_riddle_for_core(1, 0)
      riddle.sql_user.should == ENV['USER']
    end

    it "should assign attributes" do
      # 3 internal attributes plus the one requested
      @riddle.sql_attr_uint.length.should == 4
      @riddle.sql_attr_uint.last.should == :internal_id

      @riddle.sql_attr_timestamp.length.should == 1
      @riddle.sql_attr_timestamp.first.should == :birthday
    end

    it "should not include an attribute definition for polymorphic references without data" do
      @riddle.sql_attr_uint.select { |uint|
        uint == :source_id
      }.should be_empty
    end

    it "should set Sphinx Source options" do
      @riddle.sql_range_step.should      == 1000
      @riddle.sql_ranged_throttle.should == 100
    end

    describe "#sql_query" do
      before :each do
        @query = @riddle.sql_query
      end

      it "should select data from the model table" do
        @query.should match(/FROM `people`/)
      end

      it "should select each of the fields" do
        @query.should match(/`first_name`.+FROM/)
        @query.should match(/`last_name`.+FROM/)
      end

      it "should select each of the attributes" do
        @query.should match(/`id` AS `internal_id`.+FROM/)
        @query.should match(/`birthday`.+FROM/)
        @query.should match(/`tags`.`id`.+ AS `tag_ids`.+FROM/)
      end

      it "should not match the sourced MVA attribute" do
        @query.should_not match(/contact_ids/)
      end

      it "should include joins for required associations" do
        @query.should match(/LEFT OUTER JOIN `tags`/)
      end

      it "should not include joins for the sourced MVA attribute" do
        @query.should_not match(/LEFT OUTER JOIN `contacts`/)
      end

      it "should include explicitly requested joins" do
        @query.should match(/LEFT OUTER JOIN `links`/)
      end

      it "should include any defined conditions" do
        @query.should match(/WHERE.+`birthday` <= NOW()/)
      end

      it "should include any defined groupings" do
        @query.should match(/GROUP BY.+`first_name`/)
      end
    end

    describe "#sql_query_range" do
      before :each do
        @query = @riddle.sql_query_range
      end

      it "should select data from the model table" do
        @query.should match(/FROM `people`/)
      end

      it "should select the minimum and the maximum ids" do
        @query.should match(/SELECT.+MIN.+MAX.+FROM/)
      end
    end

    describe "#sql_query_info" do
      before :each do
        @query = @riddle.sql_query_info
      end

      it "should select all fields from the model table" do
        @query.should match(/SELECT \* FROM `people`/)
      end

      it "should filter the primary key with the offset" do
        model_count = ThinkingSphinx.context.indexed_models.size
        @query.should match(/WHERE `id` = \(\(\$id - 1\) \/ #{model_count}\)/)
      end
    end

    describe "#sql_query_pre" do
      before :each do
        @queries = @riddle.sql_query_pre
      end

      it "should default to just the UTF8 statement" do
        @queries.detect { |query|
          query == "SET NAMES utf8"
        }.should_not be_nil
      end

      it "should set the group_concat_max_len session value for MySQL if requested" do
        @queries.detect { |query|
          query == "SET SESSION group_concat_max_len = 1024"
        }.should_not be_nil
      end
    end
  end

  describe "#to_riddle_for_core with range disabled" do
    before :each do
      ThinkingSphinx::Field.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:first_name)
      )
    end

    describe "set per-index" do
      before :each do
        @index.local_options[:disable_range] = true
        @riddle = @source.to_riddle_for_core(1, 0)
      end

      it "should not have the range in the sql_query" do
        @riddle.sql_query.should_not match(/`people`.`id` >= \$start/)
        @riddle.sql_query.should_not match(/`people`.`id` <= \$end/)
      end

      it "should not have a sql_query_range" do
        @riddle.sql_query_range.should be_nil
      end
    end

    describe "set globally" do
      before :each do
        ThinkingSphinx::Configuration.instance.index_options[:disable_range] = true
        @riddle = @source.to_riddle_for_core(1, 0)
      end

      it "should not have the range in the sql_query" do
        @riddle.sql_query.should_not match(/`people`.`id` >= \$start/)
        @riddle.sql_query.should_not match(/`people`.`id` <= \$end/)
      end

      it "should not have a sql_query_range" do
        @riddle.sql_query_range.should be_nil
      end
    end
  end
end
