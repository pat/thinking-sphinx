# This overriding approach is only available in Rails 5.2+. This behaviour
# was preceded by AssociationReflection for Rails 4.1-5.1.
class ThinkingSphinx::ActiveRecord::Depolymorph::OverriddenReflection <
  ThinkingSphinx::ActiveRecord::Depolymorph::BaseReflection

  module JoinConstraint
    def build_join_constraint(table, foreign_table)
      super.and(
        foreign_table[options[:foreign_type]].eq(
          options[:class_name].constantize.base_class.name
        )
      )
    end
  end

  def self.overridden_classes
    @overridden_classes ||= {}
  end

  def call
    klass.new name, nil, options, reflection.active_record
  end

  private

  def klass
    self.class.overridden_classes[reflection.class] ||= begin
      subclass = Class.new reflection.class
      subclass.include JoinConstraint
      subclass
    end
  end
end
