# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::FilterReflection
  ReflectionGenerator = case ActiveRecord::VERSION::STRING.to_f
  when 5.2..7.0
    ThinkingSphinx::ActiveRecord::Depolymorph::OverriddenReflection
  when 4.1..5.1
    ThinkingSphinx::ActiveRecord::Depolymorph::AssociationReflection
  when 4.0
    ThinkingSphinx::ActiveRecord::Depolymorph::ScopedReflection
  when 3.2
    ThinkingSphinx::ActiveRecord::Depolymorph::ConditionsReflection
  end

  def self.call(reflection, name, class_name)
    ReflectionGenerator.new(reflection, name, class_name).call
  end
end
