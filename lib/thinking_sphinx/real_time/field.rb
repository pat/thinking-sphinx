# frozen_string_literal: true

class ThinkingSphinx::RealTime::Field < ThinkingSphinx::RealTime::Property
  include ThinkingSphinx::Core::Field

  def translate(object)
    Array(super || '').join(' ')
  end
end
