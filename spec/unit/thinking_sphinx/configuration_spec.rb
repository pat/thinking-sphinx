require 'spec/spec_helper'

describe ThinkingSphinx::Configuration do
  describe "build method" do
    #
  end
  
  describe "core_index_for_model method" do
    before :each do
      @config = ThinkingSphinx::Configuration.new
      @model  = Class.stub_instance(
        :indexes  => [],
        :name     => "SpecModel"
      )
    end
    
    it "should take its name from the model, with _core appended" do
      @config.send(:core_index_for_model, @model, "my sources").should match(
        /index specmodel_core/
      )
    end
    
    it "should set the path to follow the name" do
      @config.searchd_file_path = "/my/file/path"
      @config.send(:core_index_for_model, @model, "my sources").should match(
        /path = \/my\/file\/path\/specmodel_core/
      )
    end
    
    it "should include the charset type setting" do
      @config.charset_type = "specchars"
      @config.send(:core_index_for_model, @model, "my sources").should match(
        /charset_type = specchars/
      )
    end
    
    it "should include the morphology setting if it isn't blank" do
      @config.morphology = "morph"
      @config.send(:core_index_for_model, @model, "my sources").should match(
        /morphology\s+= morph/
      )
    end
    
    it "should not include the morphology setting if it is blank" do
      @config.morphology = nil
      @config.send(:core_index_for_model, @model, "my sources").should_not match(
        /morphology\s+=/
      )
      
      @config.morphology = ""
      @config.send(:core_index_for_model, @model, "my sources").should_not match(
        /morphology\s+=/
      )
    end
    
    it "should include the charset_table value if it isn't nil" do
      @config.charset_table = "table_chars"
      @config.send(:core_index_for_model, @model, "my sources").should match(
        /charset_table\s+= table_chars/
      )
    end
    
    it "should not set the charset_table value if it is nil" do
      @config.charset_table = nil
      @config.send(:core_index_for_model, @model, "my sources").should_not match(
        /charset_table\s+=/
      )      
    end
    
    it "should set the ignore_chars value if it isn't nil" do
      @config.ignore_chars = "ignorable"
      @config.send(:core_index_for_model, @model, "my sources").should match(
        /ignore_chars\s+= ignorable/
      )
    end
    
    it "should not set the ignore_chars value if it is nil" do
      @config.ignore_chars = nil
      @config.send(:core_index_for_model, @model, "my sources").should_not match(
        /ignore_chars\s+=/
      )
    end
    
    it "should include the star-related settings when allow_star is true" do
      @config.allow_star = true
      text =  @config.send(:core_index_for_model, @model, "my sources")
      
      text.should match(/enable_star\s+= 1/)
      text.should match(/min_prefix_len\s+= 1/)
      text.should match(/min_infix_len\s+= 1/)
    end
    
    it "should not include the star-related settings when allow_star is false" do
      @config.allow_star = false
      text =  @config.send(:core_index_for_model, @model, "my sources")
      
      text.should_not match(/enable_star\s+=/)
      text.should_not match(/min_prefix_len\s+=/)
      text.should_not match(/min_infix_len\s+=/)
    end
    
    it "should set prefix_fields if any fields are flagged explicitly" do
      @index = ThinkingSphinx::Index.stub_instance(
        :prefix_fields => ["a", "b", "c"],
        :infix_fields  => ["d", "e", "f"]
      )
      @model.stub_method(:indexes => [@index])
      
      @config.send(:core_index_for_model, @model, "my sources").should match(
        /prefix_fields\s+= a, b, c/
      )
    end
    
    it "shouldn't set prefix_fields if none are flagged explicitly" do
      @config.send(:core_index_for_model, @model, "my sources").should_not match(
        /prefix_fields\s+=/
      )
    end
    
    it "should set infix_fields if any fields are flagged explicitly" do
      @index = ThinkingSphinx::Index.stub_instance(
        :prefix_fields => ["a", "b", "c"],
        :infix_fields  => ["d", "e", "f"]
      )
      @model.stub_method(:indexes => [@index])
      
      @config.send(:core_index_for_model, @model, "my sources").should match(
        /infix_fields\s+= d, e, f/
      )
    end
    
    it "shouldn't set infix_fields if none are flagged explicitly" do
      @config.send(:core_index_for_model, @model, "my sources").should_not match(
        /infix_fields\s+=/
      )
    end
  end
  
  describe "delta_index_for_model method" do
    before :each do
      @config = ThinkingSphinx::Configuration.new
      @model  = Class.stub_instance(
        :name     => "SpecModel"
      )
    end
    
    it "should take its name from the model, with _delta appended" do
      @config.send(:delta_index_for_model, @model, "delta_sources").should match(
        /index specmodel_delta/
      )
    end
    
    it "should inherit from the equivalent core index" do
      @config.send(:delta_index_for_model, @model, "delta_sources").should match(
        /index specmodel_delta : specmodel_core/
      )
    end
    
    it "should set the path to follow the name" do
      @config.searchd_file_path = "/my/file/path"
      @config.send(:delta_index_for_model, @model, "delta_sources").should match(
        /path = \/my\/file\/path\/specmodel_delta/
      )
    end
  end
  
  describe "distributed_index_for_model method" do
    before :each do
      @config = ThinkingSphinx::Configuration.new
      @model  = Class.stub_instance(
        :name     => "SpecModel",
        :indexes  => []
      )
    end
    
    it "should take its name from the model" do
      @config.send(:distributed_index_for_model, @model).should match(
        /index specmodel/
      )
    end
    
    it "should have a type of distributed" do
      @config.send(:distributed_index_for_model, @model).should match(
        /type = distributed/
      )
    end
    
    it "should include the core as a local source" do
      @config.send(:distributed_index_for_model, @model).should match(
        /local = specmodel_core/
      )
    end
    
    it "should only include the delta as a local source if an index is flagged to be delta" do
      @config.send(:distributed_index_for_model, @model).should_not match(
        /local = specmodel_delta/
      )
      
      @model.stub_method(:indexes => [ThinkingSphinx::Index.stub_instance(:delta? => true)])
      @config.send(:distributed_index_for_model, @model).should match(
        /local = specmodel_delta/
      )
    end
  end
end