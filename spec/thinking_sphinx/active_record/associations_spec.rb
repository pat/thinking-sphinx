require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Associations do
  let(:model)        {
    double('model', :quoted_table_name => 'articles', :reflections => {})
  }
  let(:associations) { ThinkingSphinx::ActiveRecord::Associations.new model }
  let(:base)         {
    double('base', :active_record => model, :join_base => join_base)
  }
  let(:join_base)    { double('join base') }
  let(:reflection)   { double('reflection') }
  let(:join)         {
    double('join', :join_type= => nil, :aliased_table_name => 'users')
  }
  let(:sub_reflection) { double('sub reflection') }
  let(:sub_join)       {
    double('sub join', :join_type= => nil, :aliased_table_name => 'posts')
  }

  before :each do
    ActiveRecord::Associations::JoinDependency.stub! :new => base
    ActiveRecord::Associations::JoinDependency::JoinAssociation.
      stub! :new => join
    model.reflections[:user] = reflection

    join.stub!(
      :active_record => double('model', :reflections => {}),
      :join          => double('joiner')
    )
    join.active_record.reflections[:posts] = sub_reflection
  end

  describe '#alias_for' do
    it "returns the model's table name when no stack is given" do
      associations.alias_for([]).should == 'articles'
    end

    it "adds just one join for a stack with a single association" do
      ActiveRecord::Associations::JoinDependency::JoinAssociation.
        should_receive(:new).with(reflection, base, join_base).once.
        and_return(join)

      associations.alias_for([:user])
    end

    it "returns the aliased table name for the join" do
      associations.alias_for([:user]).should == 'users'
    end

    it "does not duplicate joins when given the same stack twice" do
      ActiveRecord::Associations::JoinDependency::JoinAssociation.
        should_receive(:new).once.and_return(join)

      associations.alias_for([:user])
      associations.alias_for([:user])
    end

    context 'multiple joins' do
      it "adds two joins for a stack with two associations" do
        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          should_receive(:new).with(reflection, base, join_base).once.
          and_return(join)

        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          should_receive(:new).with(sub_reflection, base, join.join).once.
          and_return(sub_join)

        associations.alias_for([:user, :posts])
      end

      it "returns the sub join's aliased table name" do
        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          stub(:new).and_return(join, sub_join)

        associations.alias_for([:user, :posts]).should == 'posts'
      end

      it "extends upon existing joins when given stacks where parts are already mapped" do
        ActiveRecord::Associations::JoinDependency::JoinAssociation.
          should_receive(:new).twice.and_return(join, sub_join)

        associations.alias_for([:user])
        associations.alias_for([:user, :posts])
      end
    end
  end

  describe '#join_values' do
    it "returns all joins that have been created" do
      ActiveRecord::Associations::JoinDependency::JoinAssociation.
        stub(:new).and_return(join, sub_join)

      associations.alias_for([:user])
      associations.alias_for([:user, :posts])

      associations.join_values.should == [join, sub_join]
    end
  end
end
