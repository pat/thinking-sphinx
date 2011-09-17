class ThinkingSphinx::ActiveRecord::Associations
  attr_reader :model

  def initialize(model)
    @model = model
    @joins = {}
  end

  def alias_for(stack)
    return model.quoted_table_name if stack.empty?

    build_join_for stack
    @joins[stack].aliased_table_name
  end

  def join_values
    @joins.values
  end

  private

  def base
    @base ||= ::ActiveRecord::Associations::JoinDependency.new model, [], []
  end

  def build_join_for(stack)
    parent = base
    (0..(stack.length-1)).each do |position|
      @joins[stack[0..position]] ||= ::ActiveRecord::Associations::JoinDependency::JoinAssociation.new(
        parent.active_record.reflections[stack[position]], base,
        (base == parent) ? base.join_base : parent.join
      ).tap { |join| join.join_type = Arel::OuterJoin }
      parent = @joins[stack[0..position]]
    end
  end

  def join_for(stack)
    @joins[stack] ||= build_join_for(stack)
  end
end
