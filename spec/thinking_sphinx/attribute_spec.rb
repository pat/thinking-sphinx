require 'spec/spec_helper'

describe ThinkingSphinx::Attribute do
  before :each do
    @index  = ThinkingSphinx::Index.new(Person)
    @source = ThinkingSphinx::Source.new(@index)
    
    @index.delta_object = ThinkingSphinx::Deltas::DefaultDelta.new @index, @index.local_options
  end
  
  describe '#initialize' do
    it 'raises if no columns are provided so that configuration errors are easier to track down' do
      lambda {
        ThinkingSphinx::Attribute.new(@source, [])
      }.should raise_error(RuntimeError)
    end

    it 'raises if an element of the columns param is an integer - as happens when you use id instead of :id - so that configuration errors are easier to track down' do
      lambda {
        ThinkingSphinx::Attribute.new(@source, [1234])
      }.should raise_error(RuntimeError)
    end
  end
  
  describe '#unique_name' do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new @source, [
        stub('column', :__stack => [], :__name => "col_name")
      ]
    end
    
    it "should use the alias if there is one" do
      @attribute.alias = "alias"
      @attribute.unique_name.should == "alias"
    end
    
    it "should use the alias if there's multiple columns" do
      @attribute.columns << stub('column', :__stack => [], :__name => "col_name")
      @attribute.unique_name.should be_nil
      
      @attribute.alias = "alias"
      @attribute.unique_name.should == "alias"
    end
    
    it "should use the column name if there's no alias and just one column" do
      @attribute.unique_name.should == "col_name"
    end
  end
  
  describe '#to_select_sql' do
    it "should convert a mixture of dates and datetimes to timestamps" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:created_at),
          ThinkingSphinx::Index::FauxColumn.new(:created_on) ],
        :as => :times
      )
      attribute.model = Friendship
      
      attribute.to_select_sql.should == "CONCAT_WS(',', UNIX_TIMESTAMP(`friendships`.`created_at`), UNIX_TIMESTAMP(`friendships`.`created_on`)) AS `times`"
    end
    
    it "should handle columns which don't exist for polymorphic joins" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:team, :name),
          ThinkingSphinx::Index::FauxColumn.new(:team, :league) ],
        :as => :team
      )
      
      attribute.to_select_sql.should == "CONCAT_WS(' ', IFNULL(`cricket_teams`.`name`, ''), IFNULL(`football_teams`.`name`, ''), IFNULL(`football_teams`.`league`, '')) AS `team`"
    end
  end
  
  describe '#is_many?' do
    before :each do
      @assoc_a = stub('assoc', :is_many? => true)
      @assoc_b = stub('assoc', :is_many? => true)
      @assoc_c = stub('assoc', :is_many? => true)
      
      @attribute = ThinkingSphinx::Attribute.new(
        @source, [ThinkingSphinx::Index::FauxColumn.new(:col_name)]
      )
      @attribute.associations = {
        :a => @assoc_a, :b => @assoc_b, :c => @assoc_c
      }
    end
    
    it "should return true if all associations return true to is_many?" do
      @attribute.send(:is_many?).should be_true
    end
    
    it "should return true if one association returns true to is_many?" do
      @assoc_b.stub!(:is_many? => false)
      @assoc_c.stub!(:is_many? => false)
      
      @attribute.send(:is_many?).should be_true
    end
    
    it "should return false if all associations return false to is_many?" do
      @assoc_a.stub!(:is_many? => false)
      @assoc_b.stub!(:is_many? => false)
      @assoc_c.stub!(:is_many? => false)
      
      @attribute.send(:is_many?).should be_false
    end
  end
  
  describe '#is_string?' do
    before :each do
      @col_a = ThinkingSphinx::Index::FauxColumn.new("a")
      @col_b = ThinkingSphinx::Index::FauxColumn.new("b")
      @col_c = ThinkingSphinx::Index::FauxColumn.new("c")

      @attribute = ThinkingSphinx::Attribute.new(
        @source, [@col_a, @col_b, @col_c]
      )
    end
    
    it "should return true if all columns return true to is_string?" do
      @attribute.send(:is_string?).should be_true
    end
    
    it "should return false if one column returns true to is_string?" do
      @col_a.send(:instance_variable_set, :@name, :a)
      @attribute.send(:is_string?).should be_false
    end
    
    it "should return false if all columns return false to is_string?" do
      @col_a.send(:instance_variable_set, :@name, :a)
      @col_b.send(:instance_variable_set, :@name, :b)
      @col_c.send(:instance_variable_set, :@name, :c)
      @attribute.send(:is_string?).should be_false
    end
  end
  
  describe '#type' do
    before :each do
      @column = ThinkingSphinx::Index::FauxColumn.new(:col_name)
      @attribute = ThinkingSphinx::Attribute.new(@source, [@column])
      @attribute.model = Person
      @attribute.stub!(:is_many? => false)
    end
    
    it "should return :multi if is_many? is true" do
      @attribute.stub!(:is_many? => true)
      @attribute.send(:type).should == :multi
    end
    
    it "should return :string if there's more than one association" do
      @attribute.associations = {:a => [:assoc], :b => [:assoc]}
      @attribute.send(:type).should == :string
    end
    
    it "should return the column type from the database if not :multi or more than one association" do
      @column.send(:instance_variable_set, :@name, "birthday")
      @attribute.type.should == :datetime
      
      @attribute.send(:instance_variable_set, :@type, nil)
      @column.send(:instance_variable_set, :@name, "first_name")
      @attribute.type.should == :string
      
      @attribute.send(:instance_variable_set, :@type, nil)
      @column.send(:instance_variable_set, :@name, "id")
      @attribute.type.should == :integer
    end
    
    it "should return :multi if the columns return multiple datetimes" do
      @attribute.stub!(:is_many? => true)
      @attribute.stub!(:all_datetimes? => true)
      
      @attribute.type.should == :multi
    end
    
    it "should return :bigint for 64bit integers" do
      Person.columns.detect { |col|
        col.name == 'id'
      }.stub!(:sql_type => 'BIGINT(20)')
      @column.send(:instance_variable_set, :@name, 'id')
      
      @attribute.type.should == :bigint
    end
  end
  
  describe '#all_ints?' do
    it "should return true if all columns are integers" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:id),
          ThinkingSphinx::Index::FauxColumn.new(:team_id) ]
      )
      attribute.model = Person
      attribute.columns.each { |col| attribute.associations[col] = [] }
      
      attribute.should be_all_ints
    end
    
    it "should return false if only some columns are integers" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:id),
          ThinkingSphinx::Index::FauxColumn.new(:first_name) ]
      )
      attribute.model = Person
      attribute.columns.each { |col| attribute.associations[col] = [] }
      
      attribute.should_not be_all_ints
    end
    
    it "should return false if no columns are integers" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:first_name),
          ThinkingSphinx::Index::FauxColumn.new(:last_name) ]
      )
      attribute.model = Person
      attribute.columns.each { |col| attribute.associations[col] = [] }
      
      attribute.should_not be_all_ints
    end
  end
  
  describe '#all_datetimes?' do
    it "should return true if all columns are datetimes" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:created_at),
          ThinkingSphinx::Index::FauxColumn.new(:updated_at) ]
      )
      attribute.model = Friendship
      attribute.columns.each { |col| attribute.associations[col] = [] }
      
      attribute.should be_all_datetimes
    end
    
    it "should return false if only some columns are datetimes" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:id),
          ThinkingSphinx::Index::FauxColumn.new(:created_at) ]
      )
      attribute.model = Friendship
      attribute.columns.each { |col| attribute.associations[col] = [] }
      
      attribute.should_not be_all_datetimes
    end
    
    it "should return true if all columns can be " do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:created_at),
          ThinkingSphinx::Index::FauxColumn.new(:created_on) ]
      )
      attribute.model = Friendship
      attribute.columns.each { |col| attribute.associations[col] = [] }
      
      attribute.should be_all_datetimes
    end
  end
  
  describe '#all_strings?' do
    it "should return true if all columns are strings or text" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:first_name),
          ThinkingSphinx::Index::FauxColumn.new(:last_name) ]
      )
      attribute.model = Person
      attribute.columns.each { |col| attribute.associations[col] = [] }
      
      attribute.should be_all_strings
    end
    
    it "should return false if only some columns are strings" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:id),
          ThinkingSphinx::Index::FauxColumn.new(:first_name) ]
      )
      attribute.model = Person
      attribute.columns.each { |col| attribute.associations[col] = [] }
      
      attribute.should_not be_all_strings
    end
    
    it "should return true if all columns are not strings" do
      attribute = ThinkingSphinx::Attribute.new(@source,
        [ ThinkingSphinx::Index::FauxColumn.new(:id),
          ThinkingSphinx::Index::FauxColumn.new(:parent_id) ]
      )
      attribute.model = Person
      attribute.columns.each { |col| attribute.associations[col] = [] }
      
      attribute.should_not be_all_strings
    end
  end
  
  describe "MVA with source query" do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:tags, :id)],
        :as => :tag_ids, :source => :query
      )
    end
    
    it "should use a query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query = @attribute.config_value.split('; ')
      declaration.should == "uint tag_ids from query"
      query.should       == "SELECT `tags`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `tags`.`id` AS `tag_ids` FROM `tags`"
    end
  end
  
  describe "MVA with source query for a delta source" do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:tags, :id)],
        :as => :tag_ids, :source => :query
      )
    end
    
    it "should use a query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query = @attribute.config_value(nil, true).split('; ')
      declaration.should == "uint tag_ids from query"
      query.should       == "SELECT `tags`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `tags`.`id` AS `tag_ids` FROM `tags` WHERE `tags`.`person_id` IN (SELECT `id` FROM `people` WHERE `people`.`delta` = 1)"
    end
  end
  
  describe "MVA via a HABTM association with a source query" do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:links, :id)],
        :as => :link_ids, :source => :query
      )
    end
    
    it "should use a ranged query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query = @attribute.config_value.split('; ')
      declaration.should == "uint link_ids from query"
      query.should       == "SELECT `links_people`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `links_people`.`link_id` AS `link_ids` FROM `links_people`"
    end
  end
  
  describe "MVA with ranged source query" do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:tags, :id)],
        :as => :tag_ids, :source => :ranged_query
      )
    end
    
    it "should use a ranged query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query, range_query = @attribute.config_value.split('; ')
      declaration.should == "uint tag_ids from ranged-query"
      query.should       == "SELECT `tags`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `tags`.`id` AS `tag_ids` FROM `tags` WHERE `tags`.`person_id` >= $start AND `tags`.`person_id` <= $end"
      range_query.should == "SELECT MIN(`tags`.`person_id`), MAX(`tags`.`person_id`) FROM `tags`"
    end
  end
  
  describe "MVA with ranged source query for a delta source" do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:tags, :id)],
        :as => :tag_ids, :source => :ranged_query
      )
    end
    
    it "should use a ranged query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query, range_query = @attribute.config_value(nil, true).split('; ')
      declaration.should == "uint tag_ids from ranged-query"
      query.should       == "SELECT `tags`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `tags`.`id` AS `tag_ids` FROM `tags` WHERE `tags`.`person_id` >= $start AND `tags`.`person_id` <= $end AND `tags`.`person_id` IN (SELECT `id` FROM `people` WHERE `people`.`delta` = 1)"
      range_query.should == "SELECT MIN(`tags`.`person_id`), MAX(`tags`.`person_id`) FROM `tags`"
    end
  end
  
  describe "MVA via a has-many :through with a ranged source query" do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:football_teams, :id)],
        :as => :football_team_ids, :source => :ranged_query
      )
    end
    
    it "should use a ranged query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query, range_query = @attribute.config_value.split('; ')
      declaration.should == "uint football_team_ids from ranged-query"
      query.should       == "SELECT `tags`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `tags`.`football_team_id` AS `football_team_ids` FROM `tags` WHERE `tags`.`person_id` >= $start AND `tags`.`person_id` <= $end"
      range_query.should == "SELECT MIN(`tags`.`person_id`), MAX(`tags`.`person_id`) FROM `tags`"
    end
  end
  
  describe "MVA via a has-many :through using a foreign key with a ranged source query" do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:friends, :id)],
        :as => :friend_ids, :source => :ranged_query
      )
    end
    
    it "should use a ranged query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query, range_query = @attribute.config_value.split('; ')
      declaration.should == "uint friend_ids from ranged-query"
      query.should       == "SELECT `friendships`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `friendships`.`friend_id` AS `friend_ids` FROM `friendships` WHERE `friendships`.`person_id` >= $start AND `friendships`.`person_id` <= $end"
      range_query.should == "SELECT MIN(`friendships`.`person_id`), MAX(`friendships`.`person_id`) FROM `friendships`"
    end
  end
  
  describe "MVA via a HABTM with a ranged source query" do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:links, :id)],
        :as => :link_ids, :source => :ranged_query
      )
    end
    
    it "should use a ranged query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query, range_query = @attribute.config_value.split('; ')
      declaration.should == "uint link_ids from ranged-query"
      query.should       == "SELECT `links_people`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `links_people`.`link_id` AS `link_ids` FROM `links_people` WHERE `links_people`.`person_id` >= $start AND `links_people`.`person_id` <= $end"
      range_query.should == "SELECT MIN(`links_people`.`person_id`), MAX(`links_people`.`person_id`) FROM `links_people`"
    end
  end
  
  describe "MVA via two has-many associations with a ranged source query" do
    before :each do
      @index  = ThinkingSphinx::Index.new(Alpha)
      @source = ThinkingSphinx::Source.new(@index)
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:betas, :gammas, :value)],
        :as => :gamma_values, :source => :ranged_query
      )
    end
    
    it "should use a ranged query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query, range_query = @attribute.config_value.split('; ')
      declaration.should == "uint gamma_values from ranged-query"
      query.should       == "SELECT `betas`.`alpha_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `gammas`.`value` AS `gamma_values` FROM `betas` LEFT OUTER JOIN `gammas` ON gammas.beta_id = betas.id WHERE `betas`.`alpha_id` >= $start AND `betas`.`alpha_id` <= $end"
      range_query.should == "SELECT MIN(`betas`.`alpha_id`), MAX(`betas`.`alpha_id`) FROM `betas`"
    end
  end
  
  describe "MVA via two has-many associations with a ranged source query for a delta source" do
    before :each do
      @index  = ThinkingSphinx::Index.new(Alpha)
      @source = ThinkingSphinx::Source.new(@index)
      @attribute = ThinkingSphinx::Attribute.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:betas, :gammas, :value)],
        :as => :gamma_values, :source => :ranged_query
      )
      
      @index.delta_object = ThinkingSphinx::Deltas::DefaultDelta.new @index, @index.local_options
    end
    
    it "should use a ranged query" do
      @attribute.type_to_config.should == :sql_attr_multi
      
      declaration, query, range_query = @attribute.config_value(nil, true).split('; ')
      declaration.should == "uint gamma_values from ranged-query"
      query.should       == "SELECT `betas`.`alpha_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `gammas`.`value` AS `gamma_values` FROM `betas` LEFT OUTER JOIN `gammas` ON gammas.beta_id = betas.id WHERE `betas`.`alpha_id` >= $start AND `betas`.`alpha_id` <= $end AND `betas`.`alpha_id` IN (SELECT `id` FROM `alphas` WHERE `alphas`.`delta` = 1)"
      range_query.should == "SELECT MIN(`betas`.`alpha_id`), MAX(`betas`.`alpha_id`) FROM `betas`"
    end
  end
  
  describe "with custom queries" do
    before :each do
      index = CricketTeam.sphinx_indexes.first
      @statement = index.sources.first.to_riddle_for_core(0, 0).sql_attr_multi.last
    end
    
    it "should track the query type accordingly" do
      @statement.should match(/uint tags from query/)
    end
    
    it "should include the SQL statement" do
      @statement.should match(/SELECT cricket_team_id, id FROM tags/)
    end
  end
  
  describe '#live_value' do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new @source, [
        stub('column', :__stack => [], :__name => "col_name")
      ]
      @instance = stub('model')
    end
    
    it "should translate boolean values to integers" do
      @instance.stub!(:col_name => true)
      @attribute.live_value(@instance).should == 1
      
      @instance.stub!(:col_name => false)
      @attribute.live_value(@instance).should == 0
    end
    
    it "should translate timestamps to integers" do
      now = Time.now
      @instance.stub!(:col_name => now)
      @attribute.live_value(@instance).should == now.to_i
    end
    
    it "should translate dates to timestamp integers" do
      today = Date.today
      @instance.stub!(:col_name => today)
      @attribute.live_value(@instance).should == today.to_time.to_i
    end
    
    it "should translate nils to 0" do
      @instance.stub!(:col_name => nil)
      @attribute.live_value(@instance).should == 0
    end
    
    it "should return integers as integers" do
      @instance.stub!(:col_name => 42)
      @attribute.live_value(@instance).should == 42
    end
    
    it "should handle nils in the association chain" do
      @attribute = ThinkingSphinx::Attribute.new @source, [
        stub('column', :__stack => [:assoc_name], :__name => :id)
      ]
      @instance.stub!(:assoc_name => nil)
      @attribute.live_value(@instance).should == 0
    end
    
    it "should handle association chains" do
      @attribute = ThinkingSphinx::Attribute.new @source, [
        stub('column', :__stack => [:assoc_name], :__name => :id)
      ]
      @instance.stub!(:assoc_name => stub('object', :id => 42))
      @attribute.live_value(@instance).should == 42
    end
    
    it "should translate crc strings to their integer values" do
      @attribute = ThinkingSphinx::Attribute.new @source, [
        stub('column', :__stack => [], :__name => "col_name")
      ], :crc => true, :type => :string
      @instance.stub!(:col_name => 'foo')
      @attribute.live_value(@instance).should == 'foo'.to_crc32
    end
  end
end
