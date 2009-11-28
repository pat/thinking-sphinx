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
  end
  
  describe '.define_index' do
    it "should do nothing if indexes are disabled" do
      ThinkingSphinx.define_indexes = false
      ThinkingSphinx::Index.should_not_receive(:new)
      
      Alpha.define_index { }
      
      ThinkingSphinx.define_indexes = true
    end
    
    it "should add a new index to the model" do
      index = Alpha.define_index { indexes :name }
      
      Alpha.sphinx_indexes.should include(index)
    end
    
    it "should add the model to the context collection" do
      Alpha.define_index { indexes :name }
      
      ThinkingSphinx.context.indexed_models.should include("Alpha")
    end
    
    it "should return the new index" do
      Alpha.define_index.should be_a(ThinkingSphinx::Index)
    end
    
    it "should die quietly if there is a database error" do
      ThinkingSphinx::Index::Builder.stub(:generate) { raise Mysql::Error }
      
      lambda {
        Alpha.define_index { indexes :name }
      }.should_not raise_error
    end
    
    it "should die noisily if there is a non-database error" do
      ThinkingSphinx::Index::Builder.stub(:generate) { raise StandardError }
      
      lambda {
        Alpha.define_index { indexes :name }
      }.should raise_error
    end
    
    it "should set the index's name using the parameter if provided" do
      index = Alpha.define_index('custom') { indexes :name }
      
      index.name.should == 'custom'
    end
    
    context 'callbacks' do
      it "should add a toggle_deleted callback" do
        Alpha.should_receive(:after_destroy).with(:toggle_deleted)
      
        Alpha.define_index { indexes :name }
      end
      
      it "should not add toggle_deleted callback more than once" do
        Alpha.should_receive(:after_destroy).with(:toggle_deleted).once
      
        Alpha.define_index { indexes :name }
        Alpha.define_index { indexes :name }
      end
      
      it "should add a update_attribute_values callback" do
        Alpha.should_receive(:after_commit).with(:update_attribute_values)
      
        Alpha.define_index { indexes :name }
      end
    
      it "should not add update_attribute_values callback more than once" do
        Alpha.should_receive(:after_commit).with(:update_attribute_values).once
      
        Alpha.define_index { indexes :name }
        Alpha.define_index { indexes :name }
      end
      
      it "should add a toggle_delta callback if deltas are enabled" do
        Beta.should_receive(:before_save).with(:toggle_delta)

        Beta.define_index {
          indexes :name
          set_property :delta => true
        }
      end
      
      it "should not add a toggle_delta callback if deltas are disabled" do
        Alpha.should_not_receive(:before_save).with(:toggle_delta)

        Alpha.define_index { indexes :name }
      end
      
      it "should add the toggle_delta callback if deltas are disabled in other indexes" do
        Beta.should_receive(:before_save).with(:toggle_delta).once

        Beta.define_index { indexes :name }
        Beta.define_index {
          indexes :name
          set_property :delta => true
        }
      end
      
      it "should only add the toggle_delta callback once" do
        Beta.should_receive(:before_save).with(:toggle_delta).once

        Beta.define_index {
          indexes :name
          set_property :delta => true
        }
        Beta.define_index {
          indexes :name
          set_property :delta => true
        }
      end
      
      it "should add an index_delta callback if deltas are enabled" do
        Beta.stub!(:after_commit => true)
        Beta.should_receive(:after_commit).with(:index_delta)

        Beta.define_index {
          indexes :name
          set_property :delta => true
        }
      end
      
      it "should not add an index_delta callback if deltas are disabled" do
        Alpha.should_not_receive(:after_commit).with(:index_delta)

        Alpha.define_index { indexes :name }
      end
      
      it "should add the index_delta callback if deltas are disabled in other indexes" do
        Beta.stub!(:after_commit => true)
        Beta.should_receive(:after_commit).with(:index_delta).once

        Beta.define_index { indexes :name }
        Beta.define_index {
          indexes :name
          set_property :delta => true
        }
      end
      
      it "should only add the index_delta callback once" do
        Beta.stub!(:after_commit => true)
        Beta.should_receive(:after_commit).with(:index_delta).once

        Beta.define_index {
          indexes :name
          set_property :delta => true
        }
        Beta.define_index {
          indexes :name
          set_property :delta => true
        }
      end
    end    
  end

  describe "index methods" do
    before(:all) do
      @person = Person.find(:first)
    end

    describe "in_both_indexes?" do
      it "should return true if in core and delta indexes" do
        @person.should_receive(:in_core_index?).and_return(true)
        @person.should_receive(:in_delta_index?).and_return(true)
        @person.in_both_indexes?.should be_true
      end
      
      it "should return false if in one index and not the other" do
        @person.should_receive(:in_core_index?).and_return(true)
        @person.should_receive(:in_delta_index?).and_return(false)
        @person.in_both_indexes?.should be_false
      end
    end

    describe "in_core_index?" do
      it "should call in_index? with core" do
        @person.should_receive(:in_index?).with('core')
        @person.in_core_index?
      end
    end

    describe "in_delta_index?" do
      it "should call in_index? with delta" do
        @person.should_receive(:in_index?).with('delta')
        @person.in_delta_index?
      end
    end

    describe "in_index?" do
      it "should return true if in the specified index" do
        @person.should_receive(:sphinx_document_id).and_return(1)
        @person.should_receive(:sphinx_index_name).and_return('person_core')
        Person.should_receive(:search_for_id).with(1, 'person_core').and_return(true)
      
        @person.in_index?('core').should be_true
      end
    end
  end

  describe '.source_of_sphinx_index' do
    it "should return self if model defines an index" do
      Person.source_of_sphinx_index.should == Person
    end

    it "should return the parent if model inherits an index" do
      Admin::Person.source_of_sphinx_index.should == Person
    end
  end
  
  describe '.to_crc32' do
    it "should return an integer" do
      Person.to_crc32.should be_a_kind_of(Integer)
    end
  end
    
  describe '.to_crc32s' do
    it "should return an array" do
      Person.to_crc32s.should be_a_kind_of(Array)
    end
  end
    
  describe "toggle_deleted method" do
    before :each do
      ThinkingSphinx.stub!(:sphinx_running? => true)
      
      @configuration = ThinkingSphinx::Configuration.instance
      @configuration.stub!(
        :address  => "an address",
        :port     => 123
      )
      @client = Riddle::Client.new
      @client.stub!(:update => true)
      @person = Person.find(:first)
      
      @configuration.stub!(:client => @client)
      Person.sphinx_indexes.each { |index| index.stub!(:delta? => false) }
      Person.stub!(:search_for_id => true)
    end
    
    it "should update the core index's deleted flag if in core index" do
      @client.should_receive(:update).with(
        "person_core", ["sphinx_deleted"], {@person.sphinx_document_id => [1]}
      )
      
      @person.toggle_deleted
    end
    
    it "shouldn't update the core index's deleted flag if the record isn't in it" do
      Person.stub!(:search_for_id => false)
      @client.should_not_receive(:update).with(
        "person_core", ["sphinx_deleted"], {@person.sphinx_document_id => [1]}
      )
      
      @person.toggle_deleted
    end
    
    it "shouldn't attempt to update the deleted flag if sphinx isn't running" do
      ThinkingSphinx.stub!(:sphinx_running? => false)
      @client.should_not_receive(:update)
      Person.should_not_receive(:search_for_id)
      
      @person.toggle_deleted
    end
    
    it "should update the delta index's deleted flag if delta indexes are enabled and the instance's delta is true" do
      ThinkingSphinx.deltas_enabled = true
      Person.sphinx_indexes.each { |index| index.stub!(:delta? => true) }
      @person.delta = true
      @client.should_receive(:update).with(
        "person_delta", ["sphinx_deleted"], {@person.sphinx_document_id => [1]}
      )
      
      @person.toggle_deleted
    end
    
    it "should not update the delta index's deleted flag if delta indexes are enabled and the instance's delta is false" do
      ThinkingSphinx.deltas_enabled = true
      Person.sphinx_indexes.each { |index| index.stub!(:delta? => true) }
      @person.delta = false
      @client.should_not_receive(:update).with(
        "person_delta", ["sphinx_deleted"], {@person.sphinx_document_id => [1]}
      )
      
      @person.toggle_deleted
    end
    
    it "should not update the delta index's deleted flag if delta indexes are enabled and the instance's delta is equivalent to false" do
      ThinkingSphinx.deltas_enabled = true
      Person.sphinx_indexes.each { |index| index.stub!(:delta? => true) }
      @person.delta = 0
      @client.should_not_receive(:update).with(
        "person_delta", ["sphinx_deleted"], {@person.sphinx_document_id => [1]}
      )

      @person.toggle_deleted
    end

    it "shouldn't update the delta index if delta indexes are disabled" do
      ThinkingSphinx.deltas_enabled = true
      @client.should_not_receive(:update).with(
        "person_delta", ["sphinx_deleted"], {@person.sphinx_document_id => [1]}
      )
      
      @person.toggle_deleted
    end
    
    it "should not update either index if updates are disabled" do
      ThinkingSphinx.updates_enabled = false
      ThinkingSphinx.deltas_enabled  = true
      Person.sphinx_indexes.each { |index| index.stub!(:delta? => true) }
      @person.delta = true
      @client.should_not_receive(:update)
      
      @person.toggle_deleted
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
  
  describe '#sphinx_document_id' do
    before :each do
      Alpha.define_index { indexes :name }
      Beta.define_index  { indexes :name }
    end
    
    it "should return values with the expected offset" do
      person      = Person.find(:first)
      model_count = ThinkingSphinx.context.indexed_models.length
      Person.stub!(:sphinx_offset => 3)
      
      (person.id * model_count + 3).should == person.sphinx_document_id
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
  
  describe '.sphinx_index_names' do
    it "should return the core index" do
      Alpha.define_index { indexes :name }
      Alpha.sphinx_index_names.should == ['alpha_core']
    end
    
    it "should return the delta index if enabled" do
      Beta.define_index {
        indexes :name
        set_property :delta => true
      }
      
      Beta.sphinx_index_names.should == ['beta_core', 'beta_delta']
    end
    
    it "should return the superclass with an index definition" do
      Parent.sphinx_index_names.should == ['person_core', 'person_delta']
    end
  end
  
  describe '.indexed_by_sphinx?' do
    it "should return true if there is at least one index on the model" do
      Alpha.define_index { indexes :name }
      
      Alpha.should be_indexed_by_sphinx
    end
    
    it "should return false if there are no indexes on the model" do
      Gamma.should_not be_indexed_by_sphinx
    end
  end
  
  describe '.delta_indexed_by_sphinx?' do
    it "should return true if there is at least one delta index on the model" do
      Beta.define_index {
        indexes :name
        set_property :delta => true
      }
      
      Beta.should be_delta_indexed_by_sphinx
    end
    
    it "should return false if there are no delta indexes on the model" do
      Alpha.define_index { indexes :name }
      
      Alpha.should_not be_delta_indexed_by_sphinx
    end
  end
  
  describe '.delete_in_index' do
    before :each do
      @client = stub('client')
      ThinkingSphinx.stub!(:sphinx_running? => true)
      ThinkingSphinx::Configuration.instance.stub!(:client => @client)
      Alpha.stub!(:search_for_id => true)
    end
    
    it "should not update if the document isn't in the given index" do
      Alpha.stub!(:search_for_id => false)
      @client.should_not_receive(:update)
      
      Alpha.delete_in_index('alpha_core', 42)
    end
    
    it "should direct the update to the supplied index" do
      @client.should_receive(:update) do |index, attributes, values|
        index.should == 'custom_index_core'
      end
      
      Alpha.delete_in_index('custom_index_core', 42)
    end
    
    it "should set the sphinx_deleted flag to true" do
      @client.should_receive(:update) do |index, attributes, values|
        attributes.should == ['sphinx_deleted']
        values.should == {42 => [1]}
      end
      
      Alpha.delete_in_index('alpha_core', 42)
    end
  end
  
  describe '.core_index_names' do
    it "should return each index's core name" do
      foo = Alpha.define_index { indexes :name }
      foo.name = 'foo'
      bar = Alpha.define_index { indexes :name }
      bar.name = 'bar'
      
      Alpha.core_index_names.should == ['foo_core', 'bar_core']
    end
  end
  
  describe '.delta_index_names' do
    it "should return index delta names, for indexes with deltas enabled" do
      foo = Alpha.define_index { indexes :name }
      foo.name = 'foo'
      foo.delta_object = stub('delta')
      bar = Alpha.define_index { indexes :name }
      bar.name = 'bar'
      
      Alpha.delta_index_names.should == ['foo_delta']
    end
  end
  
  describe '.sphinx_offset' do
    before :each do
      @context = ThinkingSphinx.context
    end
    
    it "should return the index of the model's name in all known indexed models" do
      @context.stub!(:indexed_models => ['Alpha', 'Beta'])
      
      Alpha.sphinx_offset.should == 0
      Beta.sphinx_offset.should  == 1
    end
    
    it "should ignore classes that have indexed superclasses" do
      @context.stub!(:indexed_models => ['Alpha', 'Parent', 'Person'])
      
      Person.sphinx_offset.should == 1
    end
    
    it "should respect first known indexed parents" do
      @context.stub!(:indexed_models => ['Alpha', 'Parent', 'Person'])
      
      Parent.sphinx_offset.should == 1
    end
  end
end
