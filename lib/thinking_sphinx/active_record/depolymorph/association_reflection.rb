# This custom association approach is only available in Rails 4.1-5.1. This
# behaviour is superseded by OverriddenReflection for Rails 5.2, and was
# preceded by ScopedReflection for Rails 4.0.
class ThinkingSphinx::ActiveRecord::Depolymorph::AssociationReflection <
  ThinkingSphinx::ActiveRecord::Depolymorph::BaseReflection

  # Since Rails 4.2, the macro argument has been removed. The underlying
  # behaviour remains the same, though.
  def call
    if explicit_macro?
      klass.new name, nil, options, reflection.active_record
    else
      klass.new reflection.macro, name, nil, options, reflection.active_record
    end
  end

  private

  def explicit_macro?
    ActiveRecord::Reflection::MacroReflection.instance_method(:initialize).
      arity == 4
  end

  def options
    super

    @options[:sphinx_internal_filtered] = true
    @options
  end
end
