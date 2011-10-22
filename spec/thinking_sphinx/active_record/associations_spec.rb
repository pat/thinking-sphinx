require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Associations do
  let(:associations) { ThinkingSphinx::ActiveRecord::Associations.new model }
  let(:model)        { model_double 'articles' }
  let(:base)         {
    double('base', :active_record => model, :join_base => join_base)
  }
  let(:join_base)    { double('join base') }
  let(:join)         { join_double 'users' }
  let(:sub_join)     { join_double 'posts' }

  def join_double(table_alias)
    double 'join',
      :join_type=         => nil,
      :aliased_table_name => table_alias,
      :reflection         => double('reflection')
  end

  def model_double(table_name = nil)
    double 'model', :quoted_table_name => table_name, :reflections => {}
  end

  before :each do
    ActiveRecord::Associations::JoinDependency.stub :new => base
    ActiveRecord::Associations::JoinDependency::JoinAssociation.
      stub(:new).and_return(join, sub_join)
    model.reflections[:user] = join.reflection

    join.stub :active_record => model_double
    join.active_record.reflections[:posts] = sub_join.reflection
  end

  describe '#add_join_to' do
    it "adds just one join for a stack with a single association" do
      ActiveRecord::Associations::JoinDependency::JoinAssociation.unstub :new
      ActiveRecord::Associations::JoinDependency::JoinAssociation.
        should_receive(:new).with(join.reflection, base, join_base).once.
        and_return(join)

      associations.add_join_to([:user])
    end

    it "does not duplicate joins when given the same stack twice" do
      ActiveRecord::Associations::JoinDependency::JoinAssociation.unstub :new
      ActiveRecord::Associations::JoinDependency::JoinAssociation.
        should_receive(:new).once.and_return(join)

      associations.add_join_to([:user])
      associations.add_join_to([:user])
    end

    context 'multiple joins' do
      it "adds two joins for a stack with two associations" do
        ActiveRecord::Associations::JoinDependency::JoinAssociation.unstub :new
        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          should_receive(:new).with(join.reflection, base, join_base).once.
          and_return(join)
        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          should_receive(:new).with(sub_join.reflection, base, join).once.
          and_return(sub_join)

        associations.add_join_to([:user, :posts])
      end

      it "extends upon existing joins when given stacks where parts are already mapped" do
        ActiveRecord::Associations::JoinDependency::JoinAssociation.unstub :new
        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          should_receive(:new).twice.and_return(join, sub_join)

        associations.add_join_to([:user])
        associations.add_join_to([:user, :posts])
      end
    end
  end

  describe '#aggregate_for?' do
    it "is false when the stack is empty" do
      associations.aggregate_for?([]).should be_false
    end

    it "is true when a reflection is a has_many" do
      join.reflection.stub!(:macro => :has_many)

      associations.aggregate_for?([:user]).should be_true
    end

    it "is true when a reflection is a has_and_belongs_to_many" do
      join.reflection.stub!(:macro => :has_and_belongs_to_many)

      associations.aggregate_for?([:user]).should be_true
    end

    it "is false when a reflection is a belongs_to" do
      join.reflection.stub!(:macro => :belongs_to)

      associations.aggregate_for?([:user]).should be_false
    end

    it "is false when a reflection is a has_one" do
      join.reflection.stub!(:macro => :has_one)

      associations.aggregate_for?([:user]).should be_false
    end

    it "is true when one level is aggregate" do
      join.reflection.stub!(:macro => :belongs_to)
      sub_join.reflection.stub!(:macro => :has_many)

      associations.aggregate_for?([:user, :posts]).should be_true
    end

    it "is true when both levels are aggregates" do
      join.reflection.stub!(:macro => :has_many)
      sub_join.reflection.stub!(:macro => :has_many)

      associations.aggregate_for?([:user, :posts]).should be_true
    end

    it "is false when both levels are not aggregates" do
      join.reflection.stub!(:macro => :belongs_to)
      sub_join.reflection.stub!(:macro => :belongs_to)

      associations.aggregate_for?([:user, :posts]).should be_false
    end
  end

  describe '#alias_for' do
    it "returns the model's table name when no stack is given" do
      associations.alias_for([]).should == 'articles'
    end

    it "adds just one join for a stack with a single association" do
      ActiveRecord::Associations::JoinDependency::JoinAssociation.unstub :new
      ActiveRecord::Associations::JoinDependency::JoinAssociation.
        should_receive(:new).with(join.reflection, base, join_base).once.
        and_return(join)

      associations.alias_for([:user])
    end

    it "returns the aliased table name for the join" do
      associations.alias_for([:user]).should == 'users'
    end

    it "does not duplicate joins when given the same stack twice" do
      ActiveRecord::Associations::JoinDependency::JoinAssociation.unstub :new
      ActiveRecord::Associations::JoinDependency::JoinAssociation.
        should_receive(:new).once.and_return(join)

      associations.alias_for([:user])
      associations.alias_for([:user])
    end

    context 'multiple joins' do
      it "adds two joins for a stack with two associations" do
        ActiveRecord::Associations::JoinDependency::JoinAssociation.unstub :new
        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          should_receive(:new).with(join.reflection, base, join_base).once.
          and_return(join)
        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          should_receive(:new).with(sub_join.reflection, base, join).once.
          and_return(sub_join)

        associations.alias_for([:user, :posts])
      end

      it "returns the sub join's aliased table name" do
        associations.alias_for([:user, :posts]).should == 'posts'
      end

      it "extends upon existing joins when given stacks where parts are already mapped" do
        ActiveRecord::Associations::JoinDependency::JoinAssociation.unstub :new
        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          should_receive(:new).twice.and_return(join, sub_join)

        associations.alias_for([:user])
        associations.alias_for([:user, :posts])
      end
    end
  end

  describe '#join_values' do
    it "returns all joins that have been created" do
      associations.alias_for([:user])
      associations.alias_for([:user, :posts])

      associations.join_values.should == [join, sub_join]
    end
  end
end
