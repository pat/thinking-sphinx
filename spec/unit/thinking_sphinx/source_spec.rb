require 'spec/spec_helper'

describe ThinkingSphinx::Source do
  before :each do
    @index  = ThinkingSphinx::Index.new(Person)
    @source = ThinkingSphinx::Source.new(@index, :sql_range_step => 1000)
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
    
    it "should assign attributes" do
      # 3 internal attributes plus the one requested
      @riddle.sql_attr_uint.length.should == 4
      @riddle.sql_attr_uint.last.should == :internal_id
      
      @riddle.sql_attr_timestamp.length.should == 1
      @riddle.sql_attr_timestamp.first.should == :birthday
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
      
      it "should include joins for required associations" do
        @query.should match(/LEFT OUTER JOIN `tags`/)
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
        model_count = ThinkingSphinx.indexed_models.size
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
end
