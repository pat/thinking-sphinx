require 'spec_helper'

describe ThinkingSphinx::Association do
  describe '.children' do
    before :each do
      @normal_reflection = stub('reflection', :options => {
        :polymorphic => false
      })
      @normal_association = ThinkingSphinx::Association.new(nil, nil)
      @poly_reflection = stub('reflection',
        :options        => {:polymorphic => true},
        :macro          => :has_many,
        :name           => 'polly',
        :active_record  => 'AR'
      )
      @non_poly_reflection = stub('reflection', :name => 'non_polly')
      
      Person.stub!(:reflect_on_association => @normal_reflection)
      ThinkingSphinx::Association.stub!(
        :new                  => @normal_association,
        :polymorphic_classes  => [Person, Person],
        :casted_options       => {:casted => :options}
      )
      ::ActiveRecord::Reflection::AssociationReflection.stub!(
        :new => @non_poly_reflection
      )
    end
    
    it "should return an empty array if no association exists" do
      Person.stub!(:reflect_on_association => nil)
      
      ThinkingSphinx::Association.children(Person, :assoc).should == []
    end
    
    it "should return a single association instance in an array if assocation isn't polymorphic" do
      ThinkingSphinx::Association.children(Person, :assoc).should == [@normal_association]
    end
    
    it "should return multiple association instances for polymorphic associations" do
      Person.stub!(:reflect_on_association => @poly_reflection)
      
      ThinkingSphinx::Association.children(Person, :assoc).should ==
        [@normal_association, @normal_association]
    end
    
    it "should generate non-polymorphic 'casted' associations for each polymorphic possibility" do
      Person.stub!(:reflect_on_association => @poly_reflection)
      ThinkingSphinx::Association.should_receive(:casted_options).with(
        Person, @poly_reflection
      ).twice
      ::ActiveRecord::Reflection::AssociationReflection.should_receive(:new).
        with(:has_many, :polly_Person, {:casted => :options}, "AR").twice
      ThinkingSphinx::Association.should_receive(:new).with(
        nil, @non_poly_reflection
      ).twice
      
      ThinkingSphinx::Association.children(Person, :assoc)
    end
  end
  
  describe '#children' do
    before :each do
      @reflection   = stub('reflection', :klass => :klass)
      @association  = ThinkingSphinx::Association.new(nil, @reflection)
      ThinkingSphinx::Association.stub!(:children => :result)
    end
    
    it "should return the children associations for the given association" do
      @association.children(:assoc).should == :result
    end
    
    it "should request children for the reflection klass" do
      ThinkingSphinx::Association.should_receive(:children).
        with(:klass, :assoc, @association)
      
      @association.children(:assoc)
    end
  end
  
  describe '#join_to' do
    before :each do
      @parent_join = stub('join assoc').as_null_object
      @join = stub('join assoc').as_null_object
      @parent = ThinkingSphinx::Association.new(nil, nil)
      @parent.stub!(:join_to => true, :join => nil)
      @base_join = stub('base join', :joins => [:a, :b, :c])
       ::ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.stub!(:new => @join)
    end
    
    it "should call the parent's join_to if parent has no join" do
      @assoc = ThinkingSphinx::Association.new(@parent, :ref)
      @parent.should_receive(:join_to).with(@base_join)
      
      @assoc.join_to(@base_join)
    end
    
    it "should not call the parent's join_to if it already has a join" do
      @assoc = ThinkingSphinx::Association.new(@parent, :ref)
      @parent.stub!(:join => @parent_join)
      @parent.should_not_receive(:join_to)
      
      @assoc.join_to(@base_join)
    end
    
    it "should define the join association with a JoinAssociation instance" do
      @assoc = ThinkingSphinx::Association.new(@parent, :ref)
      
      @assoc.join_to(@base_join).should == @join
      @assoc.join.should == @join
    end
  end
  
  describe '#to_sql' do
    before :each do
      @reflection = stub('reflection', :klass => Person)
      @association = ThinkingSphinx::Association.new(nil, @reflection)
      @parent = stub('parent', :aliased_table_name => "ALIAS TABLE NAME")
      @join = stub('join assoc',
        :to_sql => "full association join SQL",
        :parent => @parent
      )
      @association.join = @join
    end
    
    it "should return the join's association join value" do
      @association.to_sql.should == "full association join SQL"
    end
    
    it "should replace ::ts_join_alias:: with the aliased table name" do
      @join.stub!(:to_sql => "text with ::ts_join_alias:: gone")
      
      @association.to_sql.should == "text with `ALIAS TABLE NAME` gone"
    end
  end
  
  describe '#is_many?' do
    before :each do
      @parent = stub('assoc', :is_many? => :parent_is_many)
      @reflection = stub('reflection', :macro => :has_many)
    end
    
    it "should return true if association is either a has_many or a habtm" do
      association = ThinkingSphinx::Association.new(@parent, @reflection)
      association.is_many?.should be_true
      
      @reflection.stub!(:macro => :has_and_belongs_to_many)
      association.is_many?.should be_true
    end
    
    it "should return the parent value if not a has many or habtm and there is a parent" do
      association = ThinkingSphinx::Association.new(@parent, @reflection)
      @reflection.stub!(:macro => :belongs_to)
      association.is_many?.should == :parent_is_many
    end
    
    it "should return false if no parent and not a has many or habtm" do
      association = ThinkingSphinx::Association.new(nil, @reflection)
      @reflection.stub!(:macro => :belongs_to)
      association.is_many?.should be_false
    end
  end
  
  describe '#ancestors' do
    it "should return an array of associations - including all parents" do
      parent = stub('assoc', :ancestors => [:all, :ancestors])
      association = ThinkingSphinx::Association.new(parent, @reflection)
      association.ancestors.should == [:all, :ancestors, association]
    end
  end
  
  describe '.polymorphic_classes' do
    it "should return all the polymorphic result types as classes" do
      Person.connection.stub!(:select_all => [
        {"person_type" => "Person"},
        {"person_type" => "Friendship"}
      ])
      ref = stub('ref',
        :active_record  => Person,
        :options        => {:foreign_type => "person_type"}
      )
      
      ThinkingSphinx::Association.send(:polymorphic_classes, ref).should == [Person, Friendship]
    end
  end
  
  describe '.casted_options' do
    before :each do
      @options = {
        :foreign_key  => "thing_id",
        :foreign_type => "thing_type",
        :polymorphic  => true
      }
      @reflection = stub('assoc reflection', :options => @options)
    end
    
    it "should return a new options set for a specific class" do
      ThinkingSphinx::Association.send(:casted_options, Person, @reflection).should == {
        :polymorphic  => nil,
        :class_name   => "Person",
        :foreign_key  => "thing_id",
        :foreign_type => "thing_type",
        :conditions   => "::ts_join_alias::.`thing_type` = 'Person'"
      }
    end
        
    it "should append to existing Array of conditions" do
      @options[:conditions] = ["first condition"]
      ThinkingSphinx::Association.send(:casted_options, Person, @reflection).should == {
        :polymorphic  => nil,
        :class_name   => "Person",
        :foreign_key  => "thing_id",
        :foreign_type => "thing_type",
        :conditions   => ["first condition", "::ts_join_alias::.`thing_type` = 'Person'"]
      }
    end
    
    it "should merge to an existing Hash of conditions" do
      @options[:conditions] = {"field" => "value"}
      ThinkingSphinx::Association.send(:casted_options, Person, @reflection).should == {
        :polymorphic  => nil,
        :class_name   => "Person",
        :foreign_key  => "thing_id",
        :foreign_type => "thing_type",
        :conditions   => {"field" => "value", "thing_type" => "Person"}
      }
    end
    
    it "should append to an existing String of conditions" do
      @options[:conditions] = "first condition"
      ThinkingSphinx::Association.send(:casted_options, Person, @reflection).should == {
        :polymorphic  => nil,
        :class_name   => "Person",
        :foreign_key  => "thing_id",
        :foreign_type => "thing_type",
        :conditions   => "first condition AND ::ts_join_alias::.`thing_type` = 'Person'"
      }
    end
  end
end