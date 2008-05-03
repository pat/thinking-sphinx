require 'spec/spec_helper'

describe ThinkingSphinx::Search do
  describe "instance_from_result method" do
    before :each do
      Person.stub_method(:find => true)
      ThinkingSphinx::Search.stub_method(:class_from_crc => Person)
    end
    
    after :each do
      Person.unstub_method(:find)
      ThinkingSphinx::Search.unstub_method(:class_from_crc)
    end

    it "should honour the :include option" do
      ThinkingSphinx::Search.send(
        :instance_from_result,
        {:doc => 1, :attributes => {"class_crc" => 123}},
        {:include => :assoc}
      )

      Person.should have_received(:find).with(1, :include => :assoc, :select => nil)
    end

    it "should honour the :select option" do
      ThinkingSphinx::Search.send(
        :instance_from_result,
        {:doc => 1, :attributes => {"class_crc" => 123}},
        {:select => :columns}
      )

      Person.should have_received(:find).with(1, :include => nil, :select => :columns)
    end

  end

  describe "instances_from_results method" do
    before :each do
      @person_a = Person.stub_instance
      @person_b = Person.stub_instance
      @person_c = Person.stub_instance

      @results = [
        {:doc => @person_a.id},
        {:doc => @person_b.id},
        {:doc => @person_c.id}
      ]
      
      Person.stub_method(
        :find => [@person_c, @person_a, @person_b]
      )
      ThinkingSphinx::Search.stub_method(:instance_from_result => true)
    end

    after :each do
      Person.unstub_method(:find)
      ThinkingSphinx::Search.unstub_method(:instance_from_result)
    end

    it "should pass calls to instance_from_result if no class given" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results
      )

      ThinkingSphinx::Search.should have_received(:instance_from_result).with(
        {:doc => @person_a.id}, {}
      )
      ThinkingSphinx::Search.should have_received(:instance_from_result).with(
        {:doc => @person_b.id}, {}
      )
      ThinkingSphinx::Search.should have_received(:instance_from_result).with(
        {:doc => @person_c.id}, {}
      )
    end

    it "should call a find on all ids for the class" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results, {}, Person
      )
      
      Person.should have_received(:find).with(
        @person_a.id, @person_b.id, @person_c.id,
        {:include => nil, :select => nil}
      )
    end

    it "should honour the :include option" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results, {:include => :something}, Person
      )
      
      Person.should have_received(:find).with(
        @person_a.id, @person_b.id, @person_c.id,
        {:include => :something, :select => nil}
      )
    end

    it "should honour the :select option" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results, {:select => :fields}, Person
      )
      
      Person.should have_received(:find).with(
        @person_a.id, @person_b.id, @person_c.id,
        {:include => nil, :select => :fields}
      )
    end

    it "should sort the objects the same as the result set" do
      ThinkingSphinx::Search.send(
        :instances_from_results, @results, {:select => :fields}, Person
      ).should == [@person_a, @person_b, @person_c]
    end
  end
end
