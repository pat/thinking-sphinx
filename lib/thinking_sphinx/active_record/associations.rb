class ThinkingSphinx::ActiveRecord::Associations
  attr_reader :model

  def initialize(model)
    @model = model
    @joins = {}
  end

  def alias_for(stack)
    return model.quoted_table_name if stack.empty?

    join_for(stack).aliased_table_name
  end

  def join_values
    @joins.values
  end

  private

  def base
    @base ||= ::ActiveRecord::Associations::JoinDependency.new model, [], []
  end

  def join_for(stack)
    @joins[stack] ||= begin
      ::ActiveRecord::Associations::JoinDependency::JoinAssociation.new(
        reflection_for(stack), base, parent_join_for(stack)
      ).tap { |join| join.join_type = Arel::OuterJoin }
    end
  end

  def parent_for(stack)
    stack.length == 1 ? base : join_for(stack[0..-2])
  end

  def parent_join_for(stack)
    stack.length == 1 ? base.join_base : parent_for(stack).join
  end

  def reflection_for(stack)
    parent_for(stack).active_record.reflections[stack.last]
  end
end
