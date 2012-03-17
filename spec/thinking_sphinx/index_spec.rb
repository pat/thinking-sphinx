require 'spec_helper'

describe ThinkingSphinx::Index do
  describe "prefix_fields method" do
    before :each do
      @index = ThinkingSphinx::Index.new(Person)

      @field_a = stub('field', :prefixes => true)
      @field_b = stub('field', :prefixes => false)
      @field_c = stub('field', :prefixes => true)

      @index.stub!(:fields => [@field_a, @field_b, @field_c])
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

      @field_a = stub('field', :infixes => true)
      @field_b = stub('field', :infixes => false)
      @field_c = stub('field', :infixes => true)

      @index.stub!(:fields => [@field_a, @field_b, @field_c])
    end

    it "should return fields that are flagged as infixed" do
      @index.infix_fields.should include(@field_a)
      @index.infix_fields.should include(@field_c)
    end

    it "should not return fields that aren't flagged as infixed" do
      @index.infix_fields.should_not include(@field_b)
    end
  end

  describe '.name_for' do
    it "should return the model's name downcased" do
      ThinkingSphinx::Index.name_for(Alpha).should == 'alpha'
    end

    it "should separate words by underscores" do
      ThinkingSphinx::Index.name_for(ActiveRecord).should == 'active_record'
    end

    it "should separate namespaces by underscores" do
      ThinkingSphinx::Index.name_for(ActiveRecord::Base).
        should == 'active_record_base'
    end
  end

  describe '#name' do
    it "should return the downcased name of the index's model" do
      ThinkingSphinx::Index.new(Alpha).name.should == 'alpha'
    end

    it "should return a custom name if one is set" do
      index = ThinkingSphinx::Index.new(Alpha)
      index.name = 'custom'
      index.name.should == 'custom'
    end
  end

  describe '#core_name' do
    it "should take the index's name and append _core" do
      ThinkingSphinx::Index.new(Alpha).core_name.should == 'alpha_core'
    end
  end

  describe '#delta_name' do
    it "should take the index's name and append _delta" do
      ThinkingSphinx::Index.new(Alpha).delta_name.should == 'alpha_delta'
    end
  end

  describe '#all_names' do
    it "should return the core index name by default" do
      ThinkingSphinx::Index.new(Alpha).all_names.should == ['alpha_core']
    end

    it "should return both core and delta names if deltas are enabled" do
      index = ThinkingSphinx::Index.new(Alpha)
      index.delta_object = stub('delta')

      index.all_names.should == ['alpha_core', 'alpha_delta']
    end

    it "should respect custom names" do
      index = ThinkingSphinx::Index.new(Alpha)
      index.name = 'custom'

      index.all_names.should == ['custom_core']
    end

    it "should respect custom names when deltas are enabled" do
      index = ThinkingSphinx::Index.new(Alpha)
      index.name = 'custom'
      index.delta_object = stub('delta')

      index.all_names.should == ['custom_core', 'custom_delta']
    end
  end

  describe '#to_riddle' do
    it "should return two Riddle indexes if deltas are disabled" do
      index = ThinkingSphinx::Index.new(Alpha)

      index.to_riddle(0).length.should == 2
    end

    it "should return three Riddle indexes if deltas are enabled" do
      index = ThinkingSphinx::Index.new(Beta)
      index.delta_object = stub('delta')

      index.to_riddle(0).length.should == 3
    end

    it "should include a distributed index" do
      index = ThinkingSphinx::Index.new(Alpha)

      index.to_riddle(0).last.
        should be_a(Riddle::Configuration::DistributedIndex)
    end

    context 'core index' do
      it "should use the core name" do
        @index = ThinkingSphinx::Index.new(Alpha).to_riddle(0).first
        @index.name.should == 'alpha_core'
      end

      it "should not try to set disable_range on the index" do
        ThinkingSphinx::Configuration.instance.
          index_options[:disable_range] = true

        lambda {
          @index = ThinkingSphinx::Index.new(Alpha).to_riddle(0).first
        }.should_not raise_error(NoMethodError)
      end
    end

    context 'delta index' do
      before :each do
        index = ThinkingSphinx::Index.new(Beta)
        index.delta_object = stub('delta')
        @index = index.to_riddle(0)[1]
      end

      it "should use the delta name" do
        @index.name.should == 'beta_delta'
      end
    end

    context 'distributed index' do
      it "should use the index's name" do
        index = ThinkingSphinx::Index.new(Alpha)

        index.to_riddle(0).last.name.should == 'alpha'
      end

      it "should add the core index" do
        index = ThinkingSphinx::Index.new(Alpha)

        index.to_riddle(0).last.local_indices.should include('alpha_core')
      end

      it "should add the delta index if there is one" do
        index = ThinkingSphinx::Index.new(Beta)
        index.delta_object = stub('delta')

        index.to_riddle(0).last.local_indices.should include('beta_delta')
      end

      it "should add additional local indexes if there are any" do
        index = ThinkingSphinx::Index.new(Alpha)
        index.additional_indices << "other_index_core"
        index.to_riddle(0).last.local_indices.should include('other_index_core')
      end
    end
  end
end
