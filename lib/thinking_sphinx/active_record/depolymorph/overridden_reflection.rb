# frozen_string_literal: true

# This overriding approach is only available in Rails 5.2+. This behaviour
# was preceded by AssociationReflection for Rails 4.1-5.1.
class ThinkingSphinx::ActiveRecord::Depolymorph::OverriddenReflection <
  ThinkingSphinx::ActiveRecord::Depolymorph::BaseReflection

  module BuildJoinConstraint
    def build_join_constraint(table, foreign_table)
      super.and(
        foreign_table[options[:foreign_type]].eq(
          options[:class_name].constantize.base_class.name
        )
      )
    end
  end

  module JoinScope
    def join_scope(table, foreign_table, foreign_klass)
      super.where(
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
      subclass.include extension(reflection)
      subclass
    end
  end

  def extension(reflection)
    reflection.respond_to?(:build_join_constraint) ?
      BuildJoinConstraint : JoinScope
  end
end
