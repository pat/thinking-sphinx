# This scoped approach is only available in Rails 4.0. This behaviour is
# superseded by AssociationReflection for Rails 4.1, and was preceded by
# ConditionsReflection for Rails 3.2.
class ThinkingSphinx::ActiveRecord::Depolymorph::ScopedReflection <
  ThinkingSphinx::ActiveRecord::Depolymorph::BaseReflection

  def call
    klass.new reflection.macro, name, scope, options,
      reflection.active_record
  end

  private

  def scope
    lambda { |association|
      reflection = association.reflection
      klass      = reflection.class_name.constantize
      where(
        association.parent.aliased_table_name.to_sym =>
        {reflection.foreign_type => klass.base_class.name}
      )
    }
  end
end
