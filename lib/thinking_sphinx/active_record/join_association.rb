class ThinkingSphinx::ActiveRecord::JoinAssociation <
  ::ActiveRecord::Associations::JoinDependency::JoinAssociation

  def build_constraint(klass, table, key, foreign_table, foreign_key)
    constraint = super

    constraint = constraint.and(
      foreign_table[reflection.options[:foreign_type]].eq(
        base_klass.base_class.name
      )
    ) if reflection.options[:sphinx_internal_filtered]

    constraint
  end
end
