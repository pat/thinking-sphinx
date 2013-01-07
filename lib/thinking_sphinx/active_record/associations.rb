class ThinkingSphinx::ActiveRecord::Associations
  JoinDependency = ::ActiveRecord::Associations::JoinDependency

  attr_reader :model

  def initialize(model)
    @model = model
    @joins = ActiveSupport::OrderedHash.new
  end

  def add_join_to(stack)
    join_for(stack)
  end

  def aggregate_for?(stack)
    return false if stack.empty?

    joins_for(stack).any? { |join|
      [:has_many, :has_and_belongs_to_many].include?(
        join.reflection.macro
      )
    }
  end

  def alias_for(stack)
    return model.quoted_table_name if stack.empty?

    join_for(stack).aliased_table_name
  end

  def join_values
    @joins.values
  end

  def model_for(stack)
    return model if stack.empty?

    join_for(stack).reflection.klass
  end

  private

  def base
    @base ||= JoinDependency.new model, [], []
  end

  def join_for(stack)
    @joins[stack] ||= begin
      JoinDependency::JoinAssociation.new(
        reflection_for(stack), base, parent_join_for(stack)
      ).tap { |join|
        join.join_type = Arel::OuterJoin

        rewrite_conditions_for join
      }
    end
  end

  def joins_for(stack)
    if stack.length == 1
      [join_for(stack)]
    else
      [joins_for(stack[0..-2]), join_for(stack)].flatten
    end
  end

  def parent_for(stack)
    stack.length == 1 ? base : join_for(stack[0..-2])
  end

  def parent_join_for(stack)
    stack.length == 1 ? base.join_base : parent_for(stack)
  end

  def reflection_for(stack)
    parent_for(stack).active_record.reflections[stack.last]
  end

  def rewrite_conditions_for(join)
    conditions = Array(join.conditions).flatten
    conditions.each do |condition|
      condition.gsub! /::ts_join_alias::/,
        model.connection.quote_table_name(join.parent.aliased_table_name)
    end
  end
end
