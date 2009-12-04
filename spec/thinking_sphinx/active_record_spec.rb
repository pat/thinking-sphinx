require 'spec/spec_helper'

describe ThinkingSphinx::ActiveRecord do
  before :each do
    @existing_alpha_indexes = Alpha.sphinx_indexes.clone
    @existing_beta_indexes  = Beta.sphinx_indexes.clone
    
    Alpha.sphinx_indexes.clear
    Beta.sphinx_indexes.clear
  end
  
  after :each do
    Alpha.sphinx_indexes.replace @existing_alpha_indexes
    Beta.sphinx_indexes.replace  @existing_beta_indexes
    
    Alpha.sphinx_index_blocks.clear
    Beta.sphinx_index_blocks.clear
  end
  
  describe '.source_of_sphinx_index' do
    it "should return self if model defines an index" do
      Person.source_of_sphinx_index.should == Person
    end

    it "should return the parent if model inherits an index" do
      Admin::Person.source_of_sphinx_index.should == Person
    end
  end
  
  describe "sphinx_indexes in the inheritance chain (STI)" do
    it "should hand defined indexes on a class down to its child classes" do
      Child.sphinx_indexes.should include(*Person.sphinx_indexes)
    end

    it "should allow associations to other STI models" do
      source = Child.sphinx_indexes.last.sources.first
      sql = source.to_riddle_for_core(0, 0).sql_query
      sql.gsub!('$start', '0').gsub!('$end', '100')
      lambda {
        Child.connection.execute(sql)
      }.should_not raise_error(ActiveRecord::StatementInvalid)
    end
  end
  
  describe '#primary_key_for_sphinx' do
    before :each do
      @person = Person.find(:first)
    end
    
    after :each do
      Person.set_sphinx_primary_key nil
    end
    
    it "should return the id by default" do
      @person.primary_key_for_sphinx.should == @person.id
    end
    
    it "should use the sphinx primary key to determine the value" do
      Person.set_sphinx_primary_key :first_name
      @person.primary_key_for_sphinx.should == @person.first_name
    end
    
    it "should not use accessor methods but the attributes hash" do
      id = @person.id
      @person.stub!(:id => 'unique_hash')
      @person.primary_key_for_sphinx.should == id
    end
  end
end
