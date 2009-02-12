require 'spec/spec_helper'

describe ThinkingSphinx::Index do
  describe "generated sql_query" do
    it "should include explicit groupings if requested" do
      @index = ThinkingSphinx::Index.new(Person)
      
      @index.groupings << "custom_sql"
      @index.to_riddle_for_core(0, 0).sql_query.should match(/GROUP BY.+custom_sql/)
    end
  end
  
  describe "prefix_fields method" do
    before :each do
      @index = ThinkingSphinx::Index.new(Person)
      
      @field_a = ThinkingSphinx::Field.stub_instance(:prefixes => true)
      @field_b = ThinkingSphinx::Field.stub_instance(:prefixes => false)
      @field_c = ThinkingSphinx::Field.stub_instance(:prefixes => true)
      
      @index.fields = [@field_a, @field_b, @field_c]
    end
    
    it "should return fields that are flagged as prefixed" do
      @index.prefix_fields.should include(@field_a)
      @index.prefix_fields.should include(@field_c)
    end
    
    it "should not return fields that aren't flagged as prefixed" do
      @index.prefix_fields.should_not include(@field_b)
    end
  end
  
  describe "infix_fields method" do
    before :each do
      @index = ThinkingSphinx::Index.new(Person)
      
      @field_a = ThinkingSphinx::Field.stub_instance(:infixes => true)
      @field_b = ThinkingSphinx::Field.stub_instance(:infixes => false)
      @field_c = ThinkingSphinx::Field.stub_instance(:infixes => true)
      
      @index.fields = [@field_a, @field_b, @field_c]
    end
    
    it "should return fields that are flagged as infixed" do
      @index.infix_fields.should include(@field_a)
      @index.infix_fields.should include(@field_c)
    end
    
    it "should not return fields that aren't flagged as infixed" do
      @index.infix_fields.should_not include(@field_b)
    end
  end
  
  describe "multi-value attribute as ranged-query with has-many association" do
    before :each do 
      @index = ThinkingSphinx::Index.new(Person) do
        has tags(:id), :as => :tag_ids, :source => :ranged_query
      end
      @index.link!
      
      @sql = @index.to_riddle_for_core(0, 0).sql_query
    end
    
    it "should not include attribute in select-clause sql_query" do
      @sql.should_not match(/tag_ids/)
      @sql.should_not match(/GROUP_CONCAT\(`tags`.`id`/)
    end
    
    it "should not join with association table" do
      @sql.should_not match(/LEFT OUTER JOIN `tags`/)
    end
    
    it "should include sql_attr_multi as ranged-query" do
      attribute = @index.send(:attributes).first
      attribute.send(:type_to_config).to_s.should == "sql_attr_multi"
      
      declaration, query, range_query = attribute.send(:config_value).split('; ')
      declaration.should == "uint tag_ids from ranged-query"
      query.should       == "SELECT `tags`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `tags`.`id` AS `tag_ids` FROM `tags` WHERE `tags`.`person_id` >= $start AND `tags`.`person_id` <= $end"
      range_query.should == "SELECT MIN(`tags`.`person_id`), MAX(`tags`.`person_id`) FROM `tags`"
    end
  end
  
  describe "multi-value attribute as ranged-query with has-many-through association" do
    before :each do
      @index = ThinkingSphinx::Index.new(Person) do
        has friends(:id), :as => :friend_ids, :source => :ranged_query
      end
      @index.link!
      
      @sql = @index.to_riddle_for_core(0, 0).sql_query
    end
    
    it "should not include attribute in select-clause sql_query" do
      @sql.should_not match(/friend_ids/)
      @sql.should_not match(/GROUP_CONCAT\(`friendships`.`friend_id`/)
    end
    
    it "should not join with association table" do
      @sql.should_not match(/LEFT OUTER JOIN `friendships`/)
    end
    
    it "should include sql_attr_multi as ranged-query" do
      attribute = @index.send(:attributes).first
      attribute.send(:type_to_config).to_s.should == "sql_attr_multi"
      
      declaration, query, range_query = attribute.send(:config_value).split('; ')
      declaration.should == "uint friend_ids from ranged-query"
      query.should       == "SELECT `friendships`.`person_id` #{ThinkingSphinx.unique_id_expression} AS `id`, `friendships`.`friend_id` AS `friend_ids` FROM `friendships` WHERE `friendships`.`person_id` >= $start AND `friendships`.`person_id` <= $end"
      range_query.should == "SELECT MIN(`friendships`.`person_id`), MAX(`friendships`.`person_id`) FROM `friendships`"
    end
  end
end